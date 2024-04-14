class EntryImporter
  attr_reader :current_notebook, :root_path
  def initialize(current_notebook)
    @current_notebook = current_notebook
    @root_path = current_notebook.import_path
  end

  def resolve_and_import!(identifier)

    # case identifier
    # when "stylesheets/application"
      # return render_stylesheet
    # end
    # TODO: replace hacky & brittle with more well-defined search
    # i.e. exact lookups vs just fuzzy searching
    # ALSO: need to think about how this would interact with scss templates.
    file_path = build_file_path(identifier)
    glob_path = file_path + "*"
    file_path = Dir[glob_path].select { |f| f =~ /#{file_path}(\.html|\.md|\.markdown)+/ }.reject {|f| File.directory?(f) }.first
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
    file_path =~ /\.(md|markdown|html|erb)$/
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

    # TODO: DON'T DO THIS GIT DOESN"T SET CTIME!!!!!!
    created_at = parsed_file["created_at"] || File.ctime(md_path)
    updated_at = parsed_file["updated_at"] || File.mtime(md_path)

    # if we're parsing front-mattered markdown, you don't get to define an
    # identifier separate from the file's relative path, don't want to deal
    # with collisions etc, too confusing, the ad hoc markdown is for ad hoc
    # files, loosely slapped together!
    #
    # then, we lop off `.md`, `.markdown` and `html` from the suffix
    entry_source = md_path # store the unmodified identifier as the "source"
    identifier = identifier.gsub(/\.(md|markdown|html|erb)/, "")

    # TODO: test this behaviour
    if entry_source =~ /\.erb$/
      entry_kind = "template"
    else
      entry_kind = nil
    end

    entry_attributes = parsed_file.front_matter.merge({
      "identifier" => identifier,
      "source" => entry_source,
      "occurred_at" => occurred_at,
      "body" => parsed_file.content,
      "kind" => entry_kind,
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

  def render_stylesheet
    # okay lets do the dumbest thing possible
    # reload the file everytime!!!!

    scss_path = build_file_path("stylesheets/application.css.scss")

    rendered_stylesheet = nil
    if File.exist?(scss_path)
      load_path = File.join(current_notebook.import_path, "stylesheets")

      rendered_css = SassC::Engine.new(File.read(scss_path), {
        filename: "application.css.scss",
        syntax: :scss,
        load_paths: [load_path],
      }).render

      # there can only be ONE application.css
      if to_delete = current_notebook.entries.find_by(identifier: "stylesheets/application.css")
        puts "Destroying extraneous stylesheets/application.css, so it can be replaced."
        to_delete.destroy
      end

      rendered_stylesheet = current_notebook.entries.new
      rendered_stylesheet.identifier = "stylesheets/application.css"
      rendered_stylesheet.kind = :document
      rendered_stylesheet.save!

      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new(rendered_css),
                                                    metadata: { analyzed: true },
                                                    filename: "application.css")
      # blob.analyze
      rendered_stylesheet.files.create(blob_id: blob.id, created_at: blob.created_at)
    end

    rendered_stylesheet
  end
end
