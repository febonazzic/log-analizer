class LineItem < ActiveRecord::Base
  belongs_to :good
  belongs_to :cart
end
