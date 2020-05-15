notebook = "work"
bookmarks = JSON.load(File.read("pinboard.json"))
# TODO: do i shove tags in the metadata field or into the body field?

def skip?(mark)
  mark["description"] == "Twitter"
end

def hide?(mark)
  mark["tags"].empty?
end

def mark_body(mark)
  [mark["tags"].split(" ").map { |s| "##{s}" }.join(" "), mark["extended"]].select(&:present?).join("\n\n")
end

def mark_attr(notebook, mark)
  {
    notebook: notebook,
    identifier: mark["hash"],
    url: mark["href"],
    subject: mark["description"],
    body: mark_body(mark),
    occurred_at: mark["time"],
    kind: "pinboard",
    hide: hide?(mark),
    source: "phillmv"
  }
end


bookmarks.each do |mark|
  Entry.transaction do
    next if skip?(mark)
    if e = Entry.find_by(notebook: notebook, identifier: mark["hash"])
      e.update(mark_attr(notebook, mark))
    else
      Entry.create(mark_attr(notebook, mark))
    end
  end
end
