require 'sinatra/base'
require 'sinatra/contrib'
require 'sinatra/activerecord'
require 'chartkick'
require 'maxmind/db'

require './models/user'
require './models/action'
require './models/category'
require './models/good'
require './models/line_item'
require './models/cart'

class LogAnalizer < Sinatra::Base
  register Sinatra::Contrib
  register Sinatra::ActiveRecordExtension

  set :erb, layout: :'layouts/application'
  set :database, { adapter: "sqlite3", database: "logs.sqlite3" }

  get '/' do
    erb :main
  end

  # 1
  get '/top_country_actions' do
    @countries =
      User.select("country, count(actions.id) as actions_cnt").
        joins(:actions).
        group(:country).
        each_with_object({}) {
          |country, hash| hash[country.country] = country['actions_cnt']
        }
    erb :top_country_actions
  end

  # 2
  get '/categories_liked_by_countries' do
    res = Category.all.each_with_object({}) {|c, h| h[c.title] = {}}

    Action.
      select("users.country as country, categories.title as category").
      joins("JOIN categories ON actions.path = categories.title").
      joins(:user).
      each do |rec|
        res[rec['category']].merge!({ rec['country'] => 1 }) do |_, oval, nval|
          oval.to_i + nval.to_i
        end
      end

    @results =
      res.keys.each_with_object({}) do |category, hash|
        hash[category] = res[category].max_by { |k, v| v }
      end.sort_by { |k, v| k }

    erb :categories_liked_by_countries
  end

  # 3
  get '/views_by_day_time' do
    res = Category.all.each_with_object({}) {|c, h| h[c.title] = []}

    times = {
      morning: [*5..11],
      day: [*12..16],
      evening: [*17..24],
      night: [*01..04]
    }

    Category.
      select("title as title, actions.created_at as visit_time").
      joins("join actions on actions.path = categories.title").
      each do |cat|
        res[cat['title']] << cat['visit_time']
      end

    res.transform_values! do |dates|
      day_times = { morning: 0, day: 0, evening: 0, night: 0 }

      times.each do |day_time, hours|
        dates.each do |date|
          if hours.include?(date.to_time.hour)
            day_times[day_time] += 1
          end
        end
      end

      day_times.max_by { |d, v| v }
    end

    @results = res.sort_by { |k, v| k }

    erb :views_by_day_time
  end

  # 4
  get '/server_load' do
    date = params[:report_date]&.to_time || Time.parse('2018-08-01')

    @data = Action.select('created_at, count(actions.id) as actions_cnt').
    where('created_at >= ? and created_at <= ?', date.beginning_of_day, date.end_of_day).
    group(:created_at).
    each_with_object({}) do |act, hash|
      hash[act['created_at']] = act['actions_cnt']
    end.group_by do |k, v|
      k.beginning_of_hour
    end.transform_values do |v|
      v.count
    end

    erb :server_load
  end

  # 5
  get '/same_products_of_category' do
    erb :same_products_of_category
  end

  # 6
  get '/unpaid_carts' do
    @paid_carts = Cart.where('paid_at is not null').count
    carts_count = Cart.count
    @unpaid_carts = carts_count - @paid_carts

    erb :unpaid_carts
  end

  # 7
  get '/repeated_purchases' do
    date_start = params[:date_start]&.to_time || Time.parse('2018-08-01')
    date_end = params[:date_end]&.to_time || Time.parse('2018-08-01')

    @users_cnt =
      User.
        select('users.id, count(actions.id) as pays_cnt').
        joins(:actions).
        where('actions.path like "success_pay_%" and actions.created_at between ? and ?', date_start.beginning_of_day, date_end.end_of_day).
        group(:id).
        having('pays_cnt >= 2').
        size.count

    erb :repeated_purchases
  end

  not_found do
    404
  end
end
