# Every notebook gets stored locally in our git repo, which is handled by this
# class. SyncWithGit, given a notebook and optionally an entry, will write its
# contents into the local git repo and push them or pull them as appropriate.
#
# At present, it also acts as a thin presenter to the GitAdapter.
#
# It is the responsibility of the methods calling this class to check
# and see if !Rails.application.config.skip_local_sync is true
class SyncWithGit
  attr_reader :arquivo_path, :notebook, :notebook_path, :git_adapter

  def initialize(notebook, arquivo_path = nil)
    @notebook = notebook
    @notebook_path = @notebook.to_folder_path(arquivo_path)
    @arquivo_path = arquivo_path || File.dirname(@notebook_path, 2)

    @git_adapter = GitAdapter.new(@arquivo_path)
  end

  def clone!(remote)
    FileUtils.mkdir_p(notebook_path)
    repo = Git.clone(remote, path: notebook_path)
    setup_git_config(repo)
  end

  # We need to "init" a repo and set up the appropriate git attributes
  # and custom merge driver in order to resolve conflicts appropriately.
  # TODO: Document this elsewhere? And more appropriately.
  def init!
    git_adapter.with_lock do
      repo = git_adapter.open_repo(notebook.to_folder_path(arquivo_path))


      FileUtils.cp(File.join(Rails.root, "lib", "assets", "git_defaults", ".gitattributes"), notebook_path)
      FileUtils.cp_r(File.join(Rails.root, "lib", "assets", "git_defaults", "script"), notebook_path)
      setup_git_config(repo)

      git_adapter.add_and_commit!(repo, notebook_path, "initialized repo with default settings")
    end
  end

  def setup_git_config(repo)
    repo.config("merge.newest-wins.name", "newest-wins")
    repo.config("merge.newest-wins.driver", "script/newest-wins.rb %O %A %B")
    repo.config("merge.newest-wins.recursive", "text")
    repo.config("pull.rebase", "false")
  end

  def setup_git_remote_and_key!
    git_adapter.with_lock do
      if notebook.remote.present?
        repo = git_adapter.open_repo(notebook_path)

        if repo.remotes.map(&:name).include?("origin")
          repo.remove_remote("origin")
        end

        repo.add_remote("origin", notebook.remote)

        if notebook.private_key.present?
          identities_path = File.join(arquivo_path, ".identities")
          FileUtils.mkdir_p(identities_path)

          private_key_path = File.join(identities_path, "notebook-#{notebook.id}.key")

          # TODO: the encoding + universal_newline + inserting a new line is super weird, needs to be fixed
          File.write(private_key_path, notebook.private_key.encode(notebook.private_key.encoding, universal_newline: true) + "\n")
          File.chmod(0600, private_key_path)

          # TODO: ideally we fetch the github keys from the meta API? instead of ignoring hosts
          repo.config("core.sshCommand", "ssh -o StrictHostKeyChecking=no -i #{private_key_path}")
        end
      end
    end
  end

  def sync_entry!(entry)
    raise "wtf" if notebook != entry.parent_notebook

    git_adapter.with_lock do
      exporter = SyncToDisk.new(notebook, arquivo_path)
      if entry.destroyed?
        exporter.delete_entry!(entry)
      else
        entry_folder_path = exporter.export_entry!(entry)
      end

      # TODO: if destroyed? should prob remove the file path and not add it.
      # by sheer coincidence adding the directory works, i suspect because
      # it tries adding the root folder as a whole. this behaviour is Mostly
      # Fine but will have weird side effects, like adding other files in the
      # directory in this commit
      repo = git_adapter.open_repo(notebook.to_folder_path(arquivo_path))
      git_adapter.add_and_commit!(repo, entry_folder_path, entry.identifier)
    end
  end

  def sync!(msg_suffix = nil)
    git_adapter.with_lock do
      exporter = SyncToDisk.new(notebook, arquivo_path)
      exporter.export!

      if msg_suffix
        commit_msg = "import from #{msg_suffix}"
      else
        commit_msg = "#{notebook} notebook import"
      end

      repo = git_adapter.open_repo(notebook.to_folder_path(arquivo_path))
      git_adapter.add_and_commit!(repo, notebook.to_folder_path(arquivo_path), commit_msg)
    end
  end

  def entry_log(entry)
    if !File.exist?(notebook.to_folder_path(arquivo_path))
      return []
    else
      repo = git_adapter.open_repo(notebook.to_folder_path(arquivo_path))
      full_file_path = entry.to_full_file_path(arquivo_path)

      if File.exist?(full_file_path)
        repo.log.path(full_file_path).map { |c| [c.sha, c.date] }
      else
        []
      end
    end
  end

  def get_revision(entry, sha)
    repo = git_adapter.open_repo(notebook.to_folder_path(arquivo_path))
    full_file_path = entry.to_full_file_path(arquivo_path)

    if File.exist?(full_file_path)
      repo.object("#{sha}:#{entry.to_relative_file_path}").contents
    else
      nil
    end
  end

  # -- experimental
  def push!
    Arquivo.logger.debug "Locking git repo on #{notebook_path}"
    git_adapter.with_lock do
      rejected = false
      begin
        Arquivo.logger.debug "Opening git repo on #{notebook_path}"
        repo = git_adapter.open_repo(notebook.to_folder_path(arquivo_path))
        # if a branch is not provided it defaults to 'master' which breaks now
        # that we're in a 'main' branch world
        Arquivo.logger.debug "Pushing #{repo.current_branch}"
        repo.push('origin', repo.current_branch)
      rescue Git::GitExecuteError => e
        Arquivo.logger.debug "Push Failure:\n#{e.message}"
        rejected = e.message.lines.select {|s| s =~ /\[rejected\]\.*\(fetch first\)/}.any?
      end

      if rejected
        # yeah that's right, then what huh???
        # binding.pry
      end
    end
  end

  def pull!(override_notebook: false)
    result = nil
    git_adapter.with_lock do
      begin
        repo = git_adapter.open_repo(notebook_path)

        # merging will fail without these settings, which have to be reset on
        # every clone of the repo. in the future, maybe find a way to save this
        # step via some kind of detection?
        setup_git_config(repo)

        last_commit = git_adapter.latest_commit(repo)
        # if the repo is brand new, there may not be a commit to pull, so check if nil
        if last_commit

          # i set this association up before i finished writing the code
          # so it may not actually be necessary to save it but in the meantime
          # it can't hurt to keep track:
          sync = notebook.sync_states.find_by(sha: last_commit)
          if sync.nil?
            notebook.sync_states.create(sha: last_commit)
          end
        end

        Arquivo.logger.debug "Pulling #{notebook.name}…"
        result = repo.pull("origin", repo.current_branch)

        # TODO:
        # something fucky happens when there's a merge onflict and the merge strategy isn't configured; it fetches from the repo but doesn't actually do the merging. maybe some flag the library passes down? maybe just do fetch, merge steps separately.
        case result
        when /Already up to date\./
          Arquivo.logger.debug "pull do nothing, hooray!"
        else
          Arquivo.logger.debug "time to sync. message received:\n#{result}"
          syncer = SyncFromDisk.new(notebook_path, notebook,
                                    override_notebook: override_notebook)

          deleted, changed = git_adapter.changed_yaml_since(repo, last_commit)

          syncer.import_and_sync!(deleted: deleted, changed: changed)
        end

      rescue Git::GitExecuteError => e
        Arquivo.logger.debug "Pull Failure:\n#{e.message}"
        Arquivo.logger.debug "goodbye cruel world"
        # binding.pry
      end
    end

    result
  end
  # -- end experimental
end
