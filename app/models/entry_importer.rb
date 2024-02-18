class EntryImporter
  attr_reader :current_notebook, :root_path
  def initialize(current_notebook)
    @current_notebook = current_notebook
    @root_path = current_notebook.import_path
  end

  def resolve_and_import!(identifier)
    # TODO: replace hacky & brittle with more well-defined search
    # i.e. exact lookups vs just fuzzy searching
    # ALSO: need to think about how this would interact with scss templates.
    search_path = build_file_path(identifier) + "*"
    file_path = Dir[search_path].first
    if file_path && looks_like_text?(file_path)
      # TODO: hrm, should the identifier come from the request? this will blow up somehow
      import!(identifier, file_path)
    else
      puts "couldn't find nothin' to import"
      return nil
    end
  end

  def import!(identifier, file_path)
    entry_attributes = entry_attributes_from_markdown(identifier, file_path)

    entry = add_entry!(entry_attributes)
  end

  def looks_like_text?(file_path)
    file_path =~ /\.(md|markdown|html)$/
  end

  def build_file_path(path_info)
    clean_path_info = Rack::Utils.clean_path_info(path_info)
    ::File.join(@root_path, clean_path_info)
  end

  def entry_attributes_from_markdown(identifier, md_path)
    loader = FrontMatterParser::Loader::Yaml.new(allowlist_classes: [Time, Date, DateTime])
    md_parser = FrontMatterParser::SyntaxParser::Md.new
    parsed_file = FrontMatterParser::Parser.new(md_parser, loader: loader).call(File.read(md_path))

    occurred_at = parsed_file["occurred_at"]
    if occurred_at.blank?
      # let's try to guess it from the file
      basename = File.basename(md_path)
      date = basename.match(/([0-9]{4}-*[0-9]{2}-*[0-9]{2}-*)/).to_a[0]

      # most of the time this does the right thing but it does have the habit
      # of sometimes throwing an exception
      begin
        occurred_at = DateTime.parse(date.to_s)
      rescue ArgumentError
      end

      # if still nil, let's look at the file itself
      if occurred_at.nil?
        occurred_at = File.ctime(md_path)
      end
    end

    created_at = parsed_file["created_at"] || File.ctime(md_path)
    updated_at = parsed_file["updated_at"] || File.mtime(md_path)

    # if we're parsing front-mattered markdown, you don't get to define an
    # identifier separate from the file's relative path, don't want to deal
    # with collisions etc, too confusing, the ad hoc markdown is for ad hoc
    # files, loosely slapped together!
    #
    # then, we lop off `.md`, `.markdown` and `html` from the suffix
    entry_source = identifier # store the unmodified identifier as the "source"
    identifier = identifier.gsub(/\.(md|markdown|html)/, "")

    entry_attributes = parsed_file.front_matter.merge({
      "identifier" => identifier,
      "source" => entry_source,
      "occurred_at" => occurred_at,
      "body" => parsed_file.content,
      "created_at" => created_at,
      "updated_at" => updated_at,
      skip_local_sync: true
    }).slice(*Entry.accepted_attributes)

    # handle metadata!
    metadata_keys = (parsed_file.front_matter.keys - Entry.accepted_attributes)
    if metadata_keys.any?
      # if the user has specified a non Hash value, ie "metadata: foo", then
      # throw a slightly easier to understand error here, instead of later on
      # when we try to instantiate the Entry object & the error gets thrown there.
      if entry_attributes["metadata"] && !entry_attributes["metadata"].is_a?(Hash)
        raise "I expected the 'metadata' key on #{identifier} to be Hash, but something else is going on."
      end

      entry_attributes["metadata"] ||= {}
      metadata_keys.each do |mkey|
        entry_attributes["metadata"][mkey] ||= parsed_file.front_matter[mkey]
      end
    end

    entry_attributes
  end

  def add_entry!(entry_attributes)
    identifier = entry_attributes["identifier"]

    # find or update the entry
    entry = current_notebook.entries.find_by(identifier: identifier)

    if entry
      entry.update!(entry_attributes)
    else
      entry = current_notebook.entries.create(entry_attributes)
    end

    entry
  end

end
