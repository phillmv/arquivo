# Every notebook gets stored locally in our git repo, which is handled by this
# class. #write_entry
# The name "LocalSyncer" feels awkward, which is likely a sign that
# this will be renamed soon. Maybe just GitAdapter? I need a better name
# for the concept of a local synced repo, especially since we may end up
# using this class as a kind of exporter as well.
#
# It is the responsibility of the methods calling this class to check
# and see if !Rails.application.config.skip_local_sync is true
class LocalSyncer
  attr_reader :arquivo_path, :lockfile
  def initialize(path = nil)
    # TODO: maybe replace this with a mandatory notebook argument and the optional path ovverride?
    @arquivo_path = path || Setting.get(:arquivo, :arquivo_path)
    @lockfile = File.join(@arquivo_path, "sync.lock")
  end

  def self.sync_entry(entry, path = nil)
    self.new(path).write_entry(entry)
  end

  def self.sync_notebook(notebook, msg_suffix, path = nil)
    self.new(path).write_notebook(notebook, msg_suffix)
  end

  def write_entry(entry)
    with_lock do
      exporter = Exporter.new(arquivo_path)
      entry_folder_path = exporter.export_entry!(entry)

      repo = open_repo(notebook_path(entry.parent_notebook))
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

  def entry_log(entry)
    if !File.exist?(notebook_path(entry.parent_notebook))
      return []
    else
      repo = open_repo(notebook_path(entry.parent_notebook))
      full_filepath = entry.to_full_filepath(arquivo_path)

      if File.exist?(full_filepath)
        repo.log.path(full_filepath).map { |c| [c.sha, c.date] }
      else
        []
      end
    end
  end

  def get_revision(entry, sha)
    repo = open_repo(notebook_path(entry.parent_notebook))
    full_filepath = entry.to_full_filepath(arquivo_path)

    if File.exist?(full_filepath)
      repo.object("#{sha}:#{entry.to_relative_filepath}").contents
    else
      nil
    end
  end

  # -- experiment
  def push(notebook)
    with_lock do
      rejected = false
      begin
        repo = open_repo(notebook_path(notebook))
        repo.push
      rescue Git::GitExecuteError => e
        rejected = e.message.lines.select {|s| s =~ /\[rejected\]\.*\(fetch first\)/}.any?
      end

      if rejected
        # yeah that's right, then what huh???
        binding.pry
      end
    end
  end

  def pull!(notebook)
    result = nil
    begin
      repo = open_repo(notebook_path(notebook))
      result = repo.pull

      case result
      # when /Updating.*\nFast-forward/
      #   puts "ffwd"
      #   # trigger notebook update
      #   # in order
      when /Already up to date\./
        puts "do nothing"
        # hooray!
      else
        Importer.new(arquivo_path).import!
      end

    rescue Git::GitExecuteError => e
      binding.pry
    end
    result
  end

  # -- call these methods within with_lock

  def init_repo(working_dir)
    FileUtils.mkdir_p(working_dir)
    Git.init(working_dir)
  end

  def open_repo(working_dir)
    begin
      return repo = Git.open(working_dir)
    rescue ArgumentError => e
      if e.message == "path does not exist"
        return repo = init_repo(working_dir)
      else
        raise e
      end
    end
  end

  FINE_GIT_ERRORS = [ "nothing to commit", "nothing added to commit but untracked files" ]

  def add_and_commit!(repo, path, msg)
    repo.add(path)
    begin
      repo.commit(msg)
    rescue Git::GitExecuteError => e
      unless FINE_GIT_ERRORS.any? { |s| e.message.index(s) }
        raise e
      end
    end
  end

  # -- end within_lock

  def notebook_path(notebook)
    notebook.filesystem_path(arquivo_path)
  end

  # prevents other instances of this class
  # from writing to the git repo at the same time
  def with_lock(&block)
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
