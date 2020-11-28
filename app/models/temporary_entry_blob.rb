# purpose of this table is to act as a cache
# for blobs being attached to entries
# TODO: find a way to purge these once the attachments are created in the Entry
class TemporaryEntryBlob < ApplicationRecord
  def self.given(entry, filename)
    find_by(notebook: entry.notebook,
            entry_identifier: entry.identifier,
            filename: filename)
  end

  def self.add(entry, filename)
    create(notebook: entry.notebook,
           entry_identifier: entry.identifier,
           filename: filename)
  end
end
