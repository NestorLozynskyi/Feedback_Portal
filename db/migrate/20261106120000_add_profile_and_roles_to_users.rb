class AddProfileAndRolesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string, null: false, default: ""
    add_column :users, :admin, :boolean, null: false, default: false
    add_column :users, :blocked, :boolean, null: false, default: false
    # The portal has exactly one admin.
    add_index :users, :admin, unique: true, where: "admin", name: "index_users_single_admin"
  end
end
