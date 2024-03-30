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
                                 import_path: notebook_path,
                                 skip_local_sync: true)
    else
      notebook.update(import_path: notebook_path)
    end

    notebook
  end

  def load_notebook_settings(notebook)
    if File.exist?(File.join(notebook.import_path, ".site/config.yaml"))
      config = YAML.load_file(File.join(notebook.import_path, ".site/config.yaml"), permitted_classes: Arquivo::PERMITTED_YAML, aliases: true)
      # ideally, keys match options in https://api.rubyonrails.org/v6.0.2.1/classes/ActionDispatch/Routing/UrlFor.html#method-i-url_for
      config.each do |k,v|
        notebook.settings.set(k, v)
      end
    end
  end

  def process_import_path(notebook)
    everything_paths = File.join(notebook.import_path, EVERYTHING_GLOB)
    Dir.glob(everything_paths, File::FNM_DOTMATCH).each do |file_path|

      identifier = path_to_relative_identifier(file_path, notebook.import_path)

      entry_importer = EntryImporter.new(notebook)
      if skip_file_path?(identifier, file_path)
        # Do nothing.
      elsif looks_like_text?(file_path)
        # Files that become normal entries, the content in our site.
        puts "processing #{file_path}" if Rails.env.development?
        entry_importer.import!(identifier, file_path)
      else
        # everything that is not markdown is treated a bit differently.
        puts "processing #{file_path}" if Rails.env.development?
        entry_attributes = entry_attributes_from_document(identifier, file_path)

        entry = entry_importer.add_entry!(entry_attributes)

        filename = File.basename(identifier)
        if !entry.files.blobs.find_by(filename: filename)
          blob = ActiveStorage::Blob.create_and_upload!(io: File.open(file_path),
                                                        filename: filename,
                                                        metadata: { "analyzed" => true })

          entry.files.create(blob_id: blob.id, created_at: blob.created_at)
        end
      end
    end
  end

  def skip_file_path?(identifier, file_path)
    # skip folders, nothing to do
    File.directory?(file_path) ||
      # skip .site/ files, which are special & rn do not become Entries
      identifier.index(".site/") == 0 ||
      # skip git folders, obv
      identifier.index(".git/") == 0
  end

  def looks_like_text?(file_path)
    file_path =~ /\.(md|markdown|html)$/
  end

  def entry_attributes_from_document(identifier, file_path)
    entry_kind = nil
    entry_source = identifier
    entry_body = nil

    # TODO: non-documents are still a bit experimental, still figuring out
    # how to support it properly. See StaticSiteImportExportTest.
    if identifier == "stylesheets/application.css.scss"
      # TODO: should this also be a "template"? doesn't super matter.
      entry_kind = :manifest
      entry_body = File.read(file_path)
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
      "body" => entry_body,
      "occurred_at" => File.ctime(file_path),
      "updated_at" => File.mtime(file_path),
      "kind" => entry_kind,
      "source" => entry_source,
      "hide" => true,
      skip_local_sync: true,
    }
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
    if stylesheet = notebook.entries.manifests.find_by(identifier: "stylesheets/application.css.scss")
      load_path = File.join(notebook.import_path, "stylesheets")

      rendered_css = SassC::Engine.new(stylesheet.body, {
        filename: "application.css.scss",
        syntax: :scss,
        load_paths: [load_path],
      }).render

      # there can only be ONE application.css
      if to_delete = notebook.entries.find_by(identifier: "stylesheets/application.css")
        puts "Destroying extraneous stylesheets/application.css, so it can be replaced."
        to_delete.destroy
      end

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


  def path_to_relative_identifier(file_path, import_path)
    Pathname.new(file_path).relative_path_from(import_path).to_s
  end
end
