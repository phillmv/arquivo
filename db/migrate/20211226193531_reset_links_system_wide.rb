class ResetLinksSystemWide < ActiveRecord::Migration[6.0]
  def up
    Link.delete_all
    LinkEntry.delete_all
    Notebook.find_each do |notebook|
      notebook.entries.find_each do |entry|
        EntryLinker.new(entry).link!
      end
    end
  end

  def down
  end
end
