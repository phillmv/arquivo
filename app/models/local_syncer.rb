# Every notebook gets stored locally in our git repo, which is handled by this
# class. #write_entry
# The name "LocalSyncer" feels awkward, which is likely a sign that
# this will be renamed soon. Maybe just GitAdapter? I need a better name
# for the concept of a local synced repo, especially since we may end up
# using this class as a kind of exporter as well.
class LocalSyncer
  attr_reader :arquivo_path, :lockfile
  def initialize(path)
    @arquivo_path = File.join(path, "arquivo")
    @lockfile = File.join(@arquivo_path, "sync.lock")
  end

  def self.sync_entry(entry, path = nil)
    working_dir = path || Setting.get(:arquivo, :storage_path)
    self.new(working_dir).write_entry(entry)
  end

  def self.sync_notebook(notebook, msg_suffix, path = nil)
    working_dir = path || Setting.get(:arquivo, :storage_path)
    self.new(working_dir).write_notebook(notebook, msg_suffix)
  end

  def write_entry(entry)
    with_lock do
      exporter = Exporter.new(arquivo_path)
      entry_folder_path = exporter.export_entry!(entry)

      repo = open_repo(notebook_path(entry.notebook))
      add_and_commit!(repo, entry_folder_path, entry.identifier)
    end
  end

  def write_notebook(notebook, import_path = nil)
    with_lock do
      exporter = Exporter.new(arquivo_path, notebook)
      exporter.export!

      if import_path
        commit_msg = "import from #{import_path}"
      else
        commit_msg = "#{notebook} notebook import"
      end

      repo = open_repo(notebook_path(notebook))
      add_and_commit!(repo, notebook_path(notebook), commit_msg)
    end
  end

  # -- call these methods within with_lock

  def init_repo(working_dir)
    FileUtils.mkdir_p(working_dir)
    Git.init(working_dir)
  end

  def open_repo(working_dir)
    if defined?(@repo)
      return @repo
    end

    begin
      @repo = Git.open(working_dir)
    rescue ArgumentError => e
      if e.message == "path does not exist"
        return @repo = init_repo(working_dir)
      else
        raise e
      end
    end
  end


  def add_and_commit!(repo, path, msg)
    repo.add(path)
    begin
      repo.commit(msg)
    rescue Git::GitExecuteError => e
      unless e.message.index('nothing to commit')
        raise e
      end
    end
  end

  # -- end within_lock

  def notebook_path(notebook)
    File.join(arquivo_path, notebook.to_s)
  end

  # prevents other instances of this class
  # from writing to the git repo at the same time
  def with_lock(&block)
    # globally set NOP so we can skip this from within tests
    # see `enable_local_sync` in tests
    if Rails.application.config.skip_local_sync
      return
    end

    FileUtils.mkdir_p(arquivo_path)
    counter = 0
    while File.exist?(lockfile)
      counter += 1
      sleep(0.5)
      if counter >= 60
        # TODO: replace with error logger
        raise IOError.new("Failed to grab sync lock for 60 tries")
      end
    end

    begin
      File.write(lockfile, $$)
      yield
    ensure
      File.delete(lockfile)
    end
  end
end
