class CreateTagEntries < ActiveRecord::Migration[6.0]
  def change
    create_table :tag_entries do |t|
      t.references :tag
      t.references :entry

      t.timestamps
    end
  end
end
