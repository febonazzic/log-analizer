class AddUsersTable < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :ip_address, default: '', null: false
      t.string :country, default: ''
      t.integer :user_id
    end

    add_index :users, :ip_address
  end
end
