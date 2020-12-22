class CreateLinkEntries < ActiveRecord::Migration[6.0]
  def change
    create_table :link_entries do |t|
      t.references :entry, null: false, foreign_key: true
      t.integer :link_id, null: false, index: true

      t.timestamps
    end
  end
end
