class AddCategoriesTable < ActiveRecord::Migration[6.0]
  def change
    create_table :categories do |t|
      t.string :title
    end
  end
end