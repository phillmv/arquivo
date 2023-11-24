calendar_entries = `ag -l 'kind: calendar' ~/Documents/arquivo/work`.lines.map(&:strip)

calendar_entries.each do |file|
  entry_attr = YAML.load_file(file, permitted_classes: Arquivo::PERMITTED_YAML, aliases: true)
  if entry_attr["metadata"].is_a? String
    puts "processing: #{file}"
    puts "entry looks like:\n #{entry_attr}"
    puts "-------"

    entry_attr["metadata"] = YAML.load(entry_attr["metadata"], permitted_classes: Arquivo::PERMITTED_YAML, aliases: true)

    puts "new hash:\n #{entry_attr}"

    File.write(file, entry_attr.to_yaml)
  end
end
