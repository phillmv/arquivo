class Importer
  attr_accessor :import_path
  def initialize(import_path)
    @import_path = import_path
  end

  # TODO: handle files, reprocess tags
  def import!
    raise "Path bad" unless File.exist?(import_path)

    entry_files = Dir[File.join(import_path, "/*/**/*")].grep(/yaml/)

    entry_files.each do |entry_path|
      entry = YAML.load(File.read(entry_path))
      puts "importing #{entry.identifier}"
      Entry.upsert(entry.attributes)
    end
  end
end
