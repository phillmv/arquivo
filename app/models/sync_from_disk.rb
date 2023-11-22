class SyncFromDisk
  attr_accessor :notebook_path, :override_notebook

  # pattern is notebook/year/month/day/identifier
  NOTEBOOK_GLOB = "notebooks/*" #notebook
  DIR_GLOB = "/[0-9][0-9][0-9][0-9]/*/*/*" #year/month/day/identifier
  def initialize(notebook_path, notebook = nil, override_notebook: false)
    @notebook_path = notebook_path
    @notebook = notebook
    @override_notebook = override_notebook
  end

  def self.import_all!(arquivo_path)
    raise "Path bad" unless File.exist?(arquivo_path)
    notebook_paths = File.join(arquivo_path, NOTEBOOK_GLOB)
    Dir[notebook_paths].each do |notebook_path|
      self.new(notebook_path).import!
    end
  end

  # TODO: rewrite the import to handle just the changed files.
  # might have to add some way to identify which yaml files represent entries
  # vs which files represent attachments.
  # note: needs to handle cases where the last sync commit is nil, and therfore has to import everything.
  def import_and_sync!(deleted: [], changed: [])
    notebook = import!

    # okay so we've gotten this far, we've synced the disk, etc
    # if a file was added or modified, the sync from disc should've done the right thing
    # (TODO: gotta handle attachments! what if an attachment was deleted?)
    # but it won't handle _file deletions_. so:

    deleted.each do |entry_yaml|
      entry_attributes = YAML.load(entry_yaml, permitted_classes: Arquivo::PERMITTED_YAML, aliases: true)
      entry = notebook.entries.find_by(identifier: entry_attributes["identifier"])
      entry.destroy
    end
  end


  # TODO:
  # validate folders!
  def import!
    raise "Path bad" unless File.exist?(notebook_path)

    # if we have a notebook.yaml file, we're probably dealing with a normal
    # arquivo notebook, and we can go ahead and assume that the entry folder
    # paths follow the y/m/d/id/files convention
    if File.exist?(File.join(notebook_path, "notebook.yaml"))
      notebook = import_from_arquivo_folder
    else
      # if this is not a full arquivo notebook, then it's a folder full of
      # ad-hoc markdown files and folders, and we're going to do some weird
      # stuff to make everything "just work"
      notebook = AdHocMarkdownImporter.new(notebook_path).import!
    end

    notebook
  end

  def import_from_arquivo_folder
    notebook = load_or_create_notebook(notebook_path)

    # fetch every entry yaml folder
    entry_folders_path = File.join(notebook_path, DIR_GLOB)
    entry_folders = Dir[entry_folders_path]

    updated_entry_ids = []

    entry_folders.each do |path|
      # list yaml files in this folder
      # prob a more efficient way, tbd
      entry_yaml = Dir.entries(path).select { |f| f.index("yaml") }
      entry_yaml_path = File.join(path, entry_yaml)

      # load in the attr
      begin
        entry_attributes = YAML.load(File.read(entry_yaml_path), permitted_classes: Arquivo::PERMITTED_YAML, aliases: true)

        # avoid writing to git until all the entries are done
        entry_attributes.merge!(skip_local_sync: true)
      rescue Exception => e
        puts e
        binding.pry
        next
      end

      Entry.transaction do
        entry, updated = upsert_entry!(notebook, entry_attributes)

        attach_files(entry, path)

        if updated
          updated_entry_ids << entry.identifier
        end
      end
    end

    # we're done processing all the entries for this notebook_path.
    # let's sync it to our git repo
    if updated_entry_ids.any? && !Rails.application.config.skip_local_sync
      # TODO: any way to just keep track of what got synced? yeesh this is time consuming
      # TODO: we ran this syncer because the workflow used ot be
      # write to Dropbox -> DB syncs -> Import from new folder -> make local commit
      # but we're moving away from this. Commented out because this is a WIP, might still have to support DB method
      # LocalSyncer.new(notebook, File.dirname(notebook_path)).sync!(notebook_path)
    end

    notebook
  end

  def load_or_create_notebook(notebook_path)
    # if we've supplied the notebook, don't bother loading the notebook.yaml
    # TODO: this would be a good place to a) validate the supplied notebook
    # matches the notebook.yaml, as a sanity check, and b) to then also respect
    # the override_notebook flag for testing.
    if @notebook
      return @notebook
    end
    notebook_yaml_file = File.join(notebook_path, "notebook.yaml")
    notebook_yaml = YAML.load(File.read(notebook_yaml_file), permitted_classes: Arquivo::PERMITTED_YAML, aliases: true)

    notebook = Notebook.find_by(name: notebook_yaml["name"])
    if notebook.nil?
      notebook = Notebook.create(notebook_yaml)
    end

    notebook
  end

  def attach_files(entry, entry_path)
    entry_files_path = File.join(entry_path, "files")

    if File.directory?(entry_files_path)
      # list each yaml file, preserve the ordering they were uploaded in
      Dir[File.join(entry_files_path, "*yaml")].map do |f|
        YAML.load_file(f, permitted_classes: Arquivo::PERMITTED_YAML, aliases: true)
      end.sort_by do |h|
        h["created_at"]
      end.each do |file_attr|
        # sanity check (this should never happen!)
        if entry.identifier != file_attr["entry_identifier"]
          raise "Error for #{entry_identifier}: #{file_attr["key"]} points to a diff entry."
        end

        blob_attr = file_attr.except("notebook", "entry_identifier")
        create_blob_and_file(entry, blob_attr, entry_files_path)
      end
    end

    entry
  end

  def create_blob_and_file(entry, blob_attr, entry_files_path)
    # only attach if we don't have it already
    if !entry.files.blobs.where(key: blob_attr["key"]).any?

      new_attachment_filepath = File.join(entry_files_path, blob_attr["filename"])

      blob = ActiveStorage::Blob.create(blob_attr)
      blob.upload(File.open(new_attachment_filepath))

      entry.files.create(blob_id: blob.id, created_at: blob.created_at)
    end
  end

  # TODO: might have to undo this mechanism as we move
  # from Dropbox syncing to Git Syncing and the purpose
  # changes to "ensure database matches the filesystem"

  # if identifier already exists, only update if the timestamp is newer
  # than what is in our copy
  def upsert_entry!(notebook, entry_attributes)
    identifier = entry_attributes["identifier"]

    # find or update the entry
    entry = notebook.entries.find_by(identifier: identifier)
    updated = false

    # override_notebook flag is used for testing; while testing
    # sync, because we're simulating sharing a notebook across different
    # Arquivo installs, sometimes we want to write entries in one notebook
    # and then import it in a *differently named* notebook.
    # For that reason, if override_notebook is true, we throw out the notebook
    # attribute from the entry we're loading.
    if override_notebook
      entry_attributes = entry_attributes.except("notebook")
    end

    if entry
      if entry.updated_at < entry_attributes["updated_at"]
        entry.update!(entry_attributes)
        updated = true
      end

    else
      entry = notebook.entries.create(entry_attributes)
      updated = true
    end

    [entry, updated]
  end
end
