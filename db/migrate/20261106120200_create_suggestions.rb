class CreateSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :suggestions do |t|
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.references :category, foreign_key: { on_delete: :nullify }
      t.string :title, null: false
      t.text :body, null: false
      t.string :kind, null: false
      t.string :status, null: false, default: "under_review"
      t.boolean :hidden, null: false, default: false
      t.integer :votes_count, null: false, default: 0
      t.datetime :edited_at
      t.timestamps
    end
    add_index :suggestions, :status
    add_index :suggestions, :created_at
    add_index :suggestions, :votes_count
  end
end
