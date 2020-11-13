class CreateContactEntries < ActiveRecord::Migration[6.0]
  def change
    create_table :contact_entries do |t|
      t.references :entry, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true

      t.timestamps
    end
  end
end
