def skip?(mark)
  mark["description"] == "Twitter"
end

def hide?(mark)
  mark["tags"].empty?
end

def mark_body(mark)
  [mark["tags"].split(" ").map { |s| "##{s}" }.join(" "), mark["extended"]].select(&:present?).join("\n\n")
end

def mark_attr(mark)
  {
    notebook: "work",
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

# TODO: do i shove tags in the metadata field or into the body field?

bookmarks.each do |mark|
  Entry.transaction do
    next if skip?(mark)
    if e = Entry.find_by(notebook: "work", identifier: mark["hash"])
      e.update(mark_attr(mark))
    else
      Entry.create(mark_attr(mark))
    end
  end
end
