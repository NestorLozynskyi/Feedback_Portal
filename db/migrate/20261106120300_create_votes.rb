class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :suggestion, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
    add_index :votes, %i[user_id suggestion_id], unique: true
  end
end
