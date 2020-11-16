class CreateTodoLists < ActiveRecord::Migration[6.0]
  def change
    create_table :todo_lists do |t|
      t.references :entry, null: false, foreign_key: true
      t.datetime :completed_at

      t.timestamps
    end
  end
end
