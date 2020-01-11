class AddGoodsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :goods do |t|
      t.references :category
      t.integer :goods_id
    end
  end
end
