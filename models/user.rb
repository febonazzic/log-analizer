class User < ActiveRecord::Base
  has_many :actions
  has_many :carts
end
