class AddActionsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :actions do |t|
      t.references :user
      t.string :path
      t.string :params
      t.datetime :created_at
    end
  end
end
