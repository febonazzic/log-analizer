class AddCartsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :carts do |t|
      t.references :user
      t.datetime :paid_at
    end
  end
end
