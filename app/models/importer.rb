class Importer
  attr_accessor :import_path
  def initialize(import_path)
    @import_path = import_path
  end

  # TODO: handle files, reprocess tags
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
      entry_files_path = File.join(path, "files")

      # load in the attr
      entry_attributes = YAML.load(File.read(entry_yaml_path))

      Entry.transaction do
        entry = upsert_entry!(entry_attributes)


        # TODO: handle files duh
        if File.directory?(entry_files_path)
          puts "FOLDER EXISTS"
        end
      end

      Entry.select("notebook").distinct.pluck(:notebook).each do |name|
        Notebook.find_or_create_by(name: name)
      end

    end

    # entry_files.each do |entry_path|
    #   entry = YAML.load(File.read(entry_path))
    #   puts "importing #{entry.identifier}"
    #   Entry.upsert(entry.attributes)
    # end
  end

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
