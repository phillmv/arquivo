class CreateTodoListItems < ActiveRecord::Migration[6.0]
  def change
    create_table :todo_list_items do |t|
      t.string :notebook, null: false, index: true
      t.references :entry, null: false, foreign_key: true
      t.references :todo_list, null: false, foreign_key: true
      t.boolean :checked, default: false, index: true
      t.string :source, index: true
      t.datetime :occurred_at, null: false, index: true

      t.timestamps
    end
  end
end
