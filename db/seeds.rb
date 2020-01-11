LOG_REGEXP = /(?<datetime>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}).*\s(?<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}).*(?<action>(?<=https:\/\/all_to_the_bottom.com\/).*)/i
MMDB_PATH = '' # ../GeoLite2-Country.mmdb
LOGS_PATH = '' # ../logs.txt

mmdb = MaxMind::DB.new(MMDB_PATH, mode: MaxMind::DB::MODE_MEMORY)

current_line = 0
lines_count = File.foreach(LOGS_PATH).count

File.open(LOGS_PATH).each_line do |line|
  current_line += 1
  puts "#{current_line}/#{lines_count}"

  match_line = line.match(LOG_REGEXP)
  datetime = DateTime.parse(match_line['datetime'])
  ip = match_line['ip']
  action = match_line['action'].empty? ? '/' : match_line['action']
  params = ''
  path = ''
  user_id = nil
  country = ''

  mmdb_ip_info = mmdb.get(ip)
  unless mmdb_ip_info.nil?
    if country_info = mmdb_ip_info['country']
      if country_names = country_info['names']
        country = country_names['en']
      end
    end
  end

  if user_id_match = action.match(/user_id\=(\d+)/i)
    user_id = user_id_match[1]
  end

  user = User.where(ip_address: ip, country: country).first_or_create
  user.update(user_id: user_id) unless user_id.nil?

  if action.include?('?')
    path = action.match(/(.*)\?/i)[1]
    params = action.match(/\?(.*)/i)[1]
  else
    path = action
  end

  user.actions.build(path: path, params: params, created_at: datetime).save

  unless action =~ /^(pay|success|cart|\/)/i
    Category.where(title: action).first_or_create
  end

  cart_id = nil
  if action =~ /^cart/i
    cart_id = action.match(/cart_id\=(\d+)/i)[1].to_i

    cart = user.carts.where(id: cart_id).first_or_create do |cart|
      cart.id = cart_id
    end

    prev_path = user.actions.last(2).first.path

    category = Category.find_by(title: prev_path)

    good_id = action.match(/goods_id\=(\d+)/i)[1].to_i
    Good.where(goods_id: good_id, category: category).first_or_create do |good|
      good.goods_id = good_id
    end

    line_item = cart.line_items.where(cart: cart_id, good_id: good_id).first_or_create
    line_item.increment!(:quantity, action.match(/amount\=(\d+)/i)[1].to_i)
  end

  if action =~ /^success_pay_/i
    cart_id = action.match(/success_pay_(\d+)/i)[1].to_i
    Cart.find_by(id: cart_id)&.update(paid_at: datetime)
  end
end
