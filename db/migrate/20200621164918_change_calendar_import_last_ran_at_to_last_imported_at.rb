class ChangeCalendarImportLastRanAtToLastImportedAt < ActiveRecord::Migration[6.0]
  def change
    rename_column :calendar_imports, :last_ran_at, :last_imported_at
  end
end
