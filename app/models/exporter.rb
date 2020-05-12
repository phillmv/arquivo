class Exporter
  attr_accessor :export_path
  def initialize(export_path)
    @export_path = export_path
  end

  def export!
    FileUtils.mkdir_p(export_path)

    Entry.find_each do |entry|
      puts "handling #{entry.identifier}"
      entry_folder_path = build_entry_folder_path(export_path, entry)

      FileUtils.mkdir_p(entry_folder_path)
      entry_filename = "#{entry.identifier}.yaml"

      File.write(File.join(entry_folder_path, entry_filename), entry.to_yaml)

      entry.files.find_each do |attachment|
        entry_files_folder = File.join(entry_folder_path,
                                       "files")
        FileUtils.mkdir_p(entry_files_folder)

        # attachments have blobs. gotta save both
        entry_attachment_filename = "attachment-#{attachment.id}.yaml"

        entry_attachment_path = File.join(entry_files_folder,
                                          entry_attachment_filename)
        File.write(entry_attachment_path, attachment.to_yaml)

        entry_blob = attachment.blob
        entry_blob_filename = "blob-#{attachment.id}-#{entry_blob.id}.yaml"

        entry_blob_path = File.join(entry_files_folder,
                                    entry_blob_filename)
        File.write(entry_blob_path, entry_blob_filename)

        # don't forget the actual file

        puts "entry blob #{entry_blob.id}"
        actual_file_path = File.join(entry_files_folder,
                                     entry_blob.filename.to_s)

        File.open(actual_file_path, "wb") do |io|
          io.puts entry_blob.download
        end
      end
    end
  end

  def build_entry_folder_path(path, entry)
    year_month = entry.occurred_at.strftime("%Y/%m/%d")
    id = entry.identifier

    File.join(path, entry.notebook, year_month, id)
  end
end
