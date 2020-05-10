Dir["/Users/phillmv/Dropbox/1pass/data/Notes\ \(The\ Archive\)/*"].each do |path|
  filename = path.split("/").last
  date, *tags = filename.gsub(".txt", "").split

  occurred_at = Time.parse(date)
  contents = File.read(path)

  body = tags.map { |s| "##{s}" }.join(" ") + "\n" + contents
  Entry.create(notebook: "work",
               body: body,
               occurred_at: occurred_at,
               source: "the archive")
end
