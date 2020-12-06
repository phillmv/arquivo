class RenameTemporaryEntryBlobsToBlobFilenameCache < ActiveRecord::Migration[6.0]
  def change
    rename_table :temporary_entry_blobs, :cached_blob_filenames
  end
end
