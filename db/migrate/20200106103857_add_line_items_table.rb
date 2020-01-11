class AddLineItemsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :line_items do |t|
      t.references :good
      t.references :cart
      t.integer :quantity, default: 0
    end
  end
end
