class GitAdapter
  attr_reader :arquivo_path, :lockfile
  def initialize(arquivo_path)
    @arquivo_path = arquivo_path

    # hrm, maybe do this on a per notebook_path basis instead?
    # (would have to add to .gitignore)
    @lockfile = File.join(@arquivo_path, "sync.lock")
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

  FINE_GIT_ERRORS = [ "nothing to commit", "nothing added to commit but untracked files", "no changes added to commit" ]

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
