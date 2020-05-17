class Importer
  attr_accessor :import_path
  def initialize(import_path)
    @import_path = import_path
  end

  # TODO: reprocess tags
  def import!
    raise "Path bad" unless File.exist?(import_path)

    # pattern is notebook/year/month/day/identifier
    dir_pattern = "/*/*/*/*/*"
    expand_import_path = File.join(import_path, dir_pattern)
    entry_folders = Dir[expand_import_path]

    entry_folders.each do |path|
      # list yaml files in this folder
      # prob a more efficient way, tbd
      entry_yaml = Dir.entries(path).select { |f| f.index("yaml") }
      entry_yaml_path = File.join(path, entry_yaml)

      # load in the attr
      entry_attributes = YAML.load(File.read(entry_yaml_path))

      Entry.transaction do
        entry = upsert_entry!(entry_attributes)

        attach_files(entry, path)
      end

    end

    Entry.select("notebook").distinct.pluck(:notebook).each do |name|
      Notebook.find_or_create_by(name: name)
    end
  end

  def attach_files(entry, entry_path)
    entry_files_path = File.join(entry_path, "files")

    if File.directory?(entry_files_path)
      # list each yaml file, preserve the ordering they were uploaded in
      Dir[File.join(entry_files_path, "*yaml")].map do |f|
        YAML.load_file(f)
      end.sort_by do |h|
        h["created_at"]
      end.each do |file_attr|
        # sanity check (this should never happen!)
        if entry.identifier != file_attr["entry_identifier"]
          raise "Error for #{entry_identifier}: #{file_attr["key"]} points to a diff entry."
        end

        blob_attr = file_attr.except("notebook", "entry_identifier")
        create_blob_and_file(entry, blob_attr, entry_files_path)
      end
    end

    entry
  end

  def create_blob_and_file(entry, blob_attr, entry_files_path)
    # only attach if we don't have it already
    if !entry.files.blobs.where(key: blob_attr["key"]).any?

      new_attachment_filepath = File.join(entry_files_path, blob_attr["filename"])

      blob = ActiveStorage::Blob.create(blob_attr)
      blob.upload(File.open(new_attachment_filepath))

      entry.files.create(blob_id: blob.id, created_at: blob.created_at)
    end
  end

  # if identifier already exists, only update if the timestamp is newer
  # than what is in our copy
  def upsert_entry!(entry_attributes)
    notebook, identifier = entry_attributes.fetch_values("notebook", "identifier")
    # find or update the entry
    entry = Entry.find_by(notebook: notebook, identifier: identifier)

    if entry
      if entry.updated_at < entry_attributes["updated_at"]
        entry.update(entry_attributes)
      end

      entry
    else
      Entry.create(entry_attributes)
    end
  end
end
