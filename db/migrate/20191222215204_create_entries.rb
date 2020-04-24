class CreateEntries < ActiveRecord::Migration[6.0]
  def change
    create_table :entries do |t|
      t.string :notebook, null: false
      t.text :body
      t.text :metadata
      t.string :kind
      t.string :source
      t.string :url
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.datetime :occurred_at
      t.datetime :ended_at

      t.timestamps
      t.index ["notebook"], name: "index_entries_notebook"
    end
  end
end
