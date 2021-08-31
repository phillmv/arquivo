# Generate entries for an ad-hoc folder of markdown files & other documents
class AdHocMarkdownImporter
  EVERYTHING_GLOB = "**/*"

  attr_reader :notebook_path
  def initialize(notebook_path)
    @notebook_path = notebook_path
  end

  # 1. Create a notebook for storing the entries
  # 2. Load in notebook settings.
  # 3. Iterate over all of the files in the folder
  # 4. Perform post-import processing, if any.

  def import!
    notebook = find_or_create_notebook
    load_notebook_settings(notebook)
    process_import_path(notebook)
    process_templates(notebook)

    notebook
  end

  def find_or_create_notebook
    # for now, let's guess a random notebook name
    # TODO: in the future, maybe use an env var?
    notebook_name = File.basename(notebook_path).strip

    notebook = Notebook.find_by(name: notebook_name)
    if notebook.nil?
      notebook = Notebook.create(name: notebook_name,
                                 import_path: notebook_path)
    else
      notebook.update(import_path: notebook_path)
    end

    notebook
  end

  def load_notebook_settings(notebook)
    if File.exist?(File.join(notebook.import_path, ".site/config.yaml"))
      config = YAML.load_file(File.join(notebook.import_path, ".site/config.yaml"))
      # ideally, keys match options in https://api.rubyonrails.org/v6.0.2.1/classes/ActionDispatch/Routing/UrlFor.html#method-i-url_for
      config.each do |k,v|
        notebook.settings.set(k, v)
      end
    end
  end

  def process_import_path(notebook)
    everything_paths = File.join(notebook_path, EVERYTHING_GLOB)
    Dir.glob(everything_paths, File::FNM_DOTMATCH).each do |file_path|

      identifier = path_to_relative_identifier(file_path)

      if identifier.index(".site/") == 0
        # These are special files that don't need to become Entries.
        # Do nothing.
      elsif identifier.index(".git/") == 0
        # also do nothing
      elsif file_path =~ /\.(md|markdown|html)$/
        # Files that become normal entries, the content in our site.
        puts "processing #{file_path}" if Rails.env.development?
        entry_attributes = entry_attributes_from_markdown(file_path)
        entry_attributes[:skip_local_sync] = true

        entry = add_entry!(notebook, entry_attributes)
      elsif !File.directory?(file_path)
        # everything that is not markdown is treated a bit differently.
        puts "processing #{file_path}" if Rails.env.development?

        entry_kind = nil
        entry_source = nil

        # TODO: non-documents are still a bit experimental, still figuring out
        # how to support it properly. See StaticSiteImportExportTest.
        if identifier == "stylesheets/application.css.scss"
          # TODO: tbh should probably also be a template eh?
          # I don't love the name "system"
          entry_kind = :system
        elsif identifier =~ /\.erb$/
          # idea is that templates are rendered from within context of a
          # controller, which is too painful to setup here
          entry_kind = :template
          # we store the original file name in the source field in case in the
          # future we ever support something other than erb or move sass into this
          entry_source = identifier
          identifier = identifier.gsub(".erb", "")
        else
          # by default we treat everything that is not markdown/html as a 'document'
          entry_kind = :document
        end

        entry_attributes = {
          "identifier" => identifier,
          "occurred_at" => File.ctime(file_path),
          "updated_at" => File.mtime(file_path),
          "kind" => entry_kind,
          "source" => entry_source,
          "hide" => true,
          skip_local_sync: true,
          skip_set_subject: true,
        }

        entry = add_entry!(notebook, entry_attributes)

        filename = File.basename(identifier)
        if !entry.files.blobs.find_by(filename: filename)
          blob = ActiveStorage::Blob.create_and_upload!(io: File.open(file_path),
                                                        filename: filename)

          # run analysis step synchronously, so we skip the async job.
          # for reasons i don't comprehend, in dev mode at least
          # ActiveStorage::AnalyzeJob just hangs there indefinitely, doing
          # naught to improve our lot, and this is very frustrating and further
          # i have close to zero desire to debug ActiveJob async shenanigans
          blob.analyze
          entry.files.create(blob_id: blob.id, created_at: blob.created_at)
        end
      end
    end
  end

  def process_templates(notebook)
    # TODO: cleanup, isolate/refactor. A bit awkward we do this scss render
    # step here in the sync from disk, is it not? This works as a post-import
    # step only because we don't expect to edit it, this is being done within
    # context of a one-time static import->export loop.
    # also, what about .sass files?
    #
    # now let's handle the stylesheet manifest & render it.
    # if there is a stylesheets/application.css.scss we want to render the
    # Sass and convert it to a stylesheets/application.css
    if stylesheet = notebook.entries.system.find_by(identifier: "stylesheets/application.css.scss")
      load_path = File.join(notebook.import_path, "stylesheets")
      manifest_path = File.join(load_path, "application.css.scss")

      rendered_css = SassC::Engine.new(File.read(manifest_path), {
        filename: "application.css.scss",
        syntax: :scss,
        load_paths: [load_path],
      }).render

      rendered_stylesheet = notebook.entries.new(stylesheet.export_attributes)
      rendered_stylesheet.identifier = "stylesheets/application.css"
      rendered_stylesheet.kind = :document
      rendered_stylesheet.save!

      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new(rendered_css),
                                                    filename: "application.css")
      blob.analyze
      rendered_stylesheet.files.create(blob_id: blob.id, created_at: blob.created_at)
    end
  end

  def entry_attributes_from_markdown(md_path)
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
    # with collisions etc, too confusing
    identifier = path_to_relative_identifier(md_path)
    identifier = identifier.gsub(/\.(md|markdown)/, "")

    entry_attributes = parsed_file.front_matter.merge({
      "identifier" => identifier,
      "occurred_at" => occurred_at,
      "body" => parsed_file.content,
      "created_at" => created_at,
      "updated_at" => updated_at
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

  def path_to_relative_identifier(file_path)
    Pathname.new(file_path).relative_path_from(notebook_path).to_s
  end

  # if identifier already exists, only update if the timestamp is newer
  # than what is in our copy
  def add_entry!(notebook, entry_attributes)
    identifier = entry_attributes["identifier"]

    # find or update the entry
    entry = notebook.entries.find_by(identifier: identifier)

    if entry
      entry.update!(entry_attributes)
    else
      entry = notebook.entries.create(entry_attributes)
    end

    entry
  end

end
