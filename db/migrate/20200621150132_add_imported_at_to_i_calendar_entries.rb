class AddImportedAtToICalendarEntries < ActiveRecord::Migration[6.0]
  def change
    add_column :i_calendar_entries, :last_imported_at, :datetime
  end
end
