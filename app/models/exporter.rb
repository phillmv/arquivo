class Exporter
  attr_accessor :export_path
  def initialize(export_path)
    @export_path = export_path
  end

  def export!
    FileUtils.mkdir_p(export_path)

    Entry.with_attached_files.find_each do |entry|
      puts "handling #{entry.identifier}"

      entry_folder_path = entry.to_folder_path(export_path)
      FileUtils.mkdir_p(entry_folder_path)

      File.write(File.join(entry_folder_path, entry.to_filename), entry.to_yaml)

      if entry.files.any?
        entry_files_path = File.join(entry_folder_path,
                                     "files")

        FileUtils.mkdir_p(entry_files_path)

        entry.files.each do |file|
          blob = file.blob

          # attachments have blobs. gotta save both
          entry_file_filename = "file-#{"%03d" % file.id}.yaml"

          entry_file_path = File.join(entry_files_path,
                                      entry_file_filename)
          File.write(entry_file_path, blob_attributes(entry, blob))


          puts "entry blob #{blob.id}"
          actual_file_path = File.join(entry_files_path,
                                       blob.filename.to_s)

          File.open(actual_file_path, "wb") do |io|
            io.puts blob.download
          end
        end
      end
    end
  end

  def blob_attributes(entry, blob)
    {
      "notebook" => entry.notebook,
      "entry_identifier" => entry.identifier,
      "key" => blob.key,
      "filename" => blob.filename.to_s,
      "content_type" => blob.content_type,
      "metadata" => blob.metadata,
      "byte_size" => blob.byte_size,
      "checksum" => blob.checksum,
      "created_at" => blob.created_at
    }.to_yaml
  end
end
