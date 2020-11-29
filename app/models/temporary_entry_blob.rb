# purpose of this table is to act as a cache for blobs being attached to entries
# so that we may avoid blob filename collisions.
#
# becaues of how DirectUpload works, the blob won't be associated with the entry
# until after the blob is uploaded / the url has been returned to the entry page
class TemporaryEntryBlob < ApplicationRecord
  belongs_to :entry, foreign_key: :identifier, primary_key: :entry_identifier

  def self.filename_taken?(entry, filename)
    entry.files.blobs.find_by(filename: filename) ||
      find_by(notebook: entry.notebook,
              entry_identifier: entry.identifier,
              filename: filename)
  end

  def self.add(entry, filename)
    create(notebook: entry.notebook,
           entry_identifier: entry.identifier,
           filename: filename)
  end

  def self.increment_filename_number(filename)
    file_ext = File.extname(filename)
    basename = filename.delete_suffix(file_ext)

    number = /\d+$/.match(basename).to_a[0]
    if number
      basename = basename.delete_suffix(number)
    else
      number = 1
    end

    number = number.succ
    basename = [basename,number,file_ext].join
  end
end