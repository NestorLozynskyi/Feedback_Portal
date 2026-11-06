class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :suggestion, null: false, foreign_key: { on_delete: :cascade }
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.boolean :hidden, null: false, default: false
      t.datetime :edited_at
      t.timestamps
    end
  end
end
