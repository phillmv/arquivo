class CreateEntries < ActiveRecord::Migration[6.0]
  def change
    create_table :entries do |t|
      t.text :body
      t.datetime :occurred_at

      t.timestamps
    end
  end
end
