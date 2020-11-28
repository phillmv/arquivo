class CreateTemporaryEntryBlobs < ActiveRecord::Migration[6.0]
  def change
    create_table :temporary_entry_blobs do |t|
      t.string :notebook, null: false
      t.string :entry_identifier, null: false
      t.string :filename, null: false

      t.timestamps
      t.index [:notebook, :entry_identifier, :filename], name: "idx_temp_entry_blob"
    end
  end
end
