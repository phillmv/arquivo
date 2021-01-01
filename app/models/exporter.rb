class Exporter
  attr_accessor :arquivo_path, :notebook, :notebook_path

  def self.export_all!(arquivo_path = nil)
    Notebook.find_each do |notebook|
      new(notebook, arquivo_path).export!
    end
  end

  def initialize(notebook, arquivo_path = nil)
    raise ArgumentError.new("gotta pass in a Notebook") unless notebook.is_a?(Notebook)
    @notebook = notebook
    @notebook_path = @notebook.to_folder_path(arquivo_path)
    @arquivo_path = arquivo_path || File.dirname(@notebook_path)
  end

  # TODO: don't overwrite if existing is newer
  def export!
    FileUtils.mkdir_p(notebook_path)
    File.write(notebook.to_full_file_path(arquivo_path), notebook.to_yaml)

    notebook.entries.with_attached_files.find_each do |entry|
      puts "handling #{entry.notebook}/#{entry.identifier}"

      export_entry!(entry)
    end
  end

  def export_entry!(entry)
    # set up folders
    # do we have to check this every time? prob not eh
    FileUtils.mkdir_p(notebook_path)
    File.write(notebook.to_full_file_path(arquivo_path), notebook.to_yaml)

    entry_folder_path = entry.to_folder_path(arquivo_path)
    FileUtils.mkdir_p(entry_folder_path)

    File.write(entry.to_full_file_path(arquivo_path), entry.to_yaml)

    if entry.files.any?
      entry_files_path = File.join(entry_folder_path,
                                   "files")

      FileUtils.mkdir_p(entry_files_path)

      entry.files.each_with_index do |file, i|
        export_blob!(entry, file.blob, entry_files_path, i)
      end
    end

    entry_folder_path
  end

  def export_blob!(entry, blob, entry_files_path, count)
    entry_file_filename = "file-#{count}.yaml"

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
