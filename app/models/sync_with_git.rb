# Every notebook gets stored locally in our git repo, which is handled by this
# class. #write_entry
# The name "LocalSyncer" feels awkward, which is likely a sign that
# this will be renamed soon. Maybe just GitAdapter? I need a better name
# for the concept of a local synced repo, especially since we may end up
# using this class as a kind of exporter as well.
#
# It is the responsibility of the methods calling this class to check
# and see if !Rails.application.config.skip_local_sync is true
#
# 2021/01/01 this class clearly has two responsibilities: it runs the Exporter 
# and then it SyncsWithGit. Maybe the Running the Exporter bit can instead be the
# job of the EntryMaker eh? This class could assume the Exporter has been run
class SyncWithGit
  attr_reader :arquivo_path, :notebook, :notebook_path, :git_adapter

  def initialize(notebook, arquivo_path = nil)
    @notebook = notebook
    @notebook_path = @notebook.to_folder_path(arquivo_path)
    @arquivo_path = arquivo_path || File.dirname(@notebook_path)

    @git_adapter = GitAdapter.new(@arquivo_path)
  end

  def sync_entry!(entry)
    raise "wtf" if notebook != entry.parent_notebook

    git_adapter.with_lock do
      exporter = SyncToDisk.new(notebook, arquivo_path)
      entry_folder_path = exporter.export_entry!(entry)

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

  # -- experiment
  def push(notebook)
    git_adapter.with_lock do
      rejected = false
      begin
        repo = git_adapter.open_repo(notebook.to_folder_path(arquivo_path))
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

  def pull!
    result = nil
    begin
      repo = git_adapter.open_repo(notebook_path)
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
        SyncFromDisk.new(notebook_path).import!
      end

    rescue Git::GitExecuteError => e
      binding.pry
    end
    result
  end
  # -- end experiment

end
