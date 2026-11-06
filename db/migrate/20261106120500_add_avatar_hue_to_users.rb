class AddAvatarHueToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :avatar_hue, :integer
  end
end
