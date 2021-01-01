require 'test_helper'

class LocalSyncerTest < ActiveSupport::TestCase
  test "without enable_local_sync we don't write to a git repo" do
    notebook = Notebook.create(name: "test")

    assert Rails.application.config.skip_local_sync

    arquivo_path = SyncWithGit.new(notebook).arquivo_path
    refute File.exist?(arquivo_path)
    refute arquivo_path.index("Documents")
    refute arquivo_path.index(ENV["HOME"])

    entry = notebook.entries.create(body: "foo")
    assert_equal 1, Entry.count

    # because local_sync is turned off,
    # we don't get any history from the repo
    # and the arquivo_path still does not exist
    refute File.exist?(arquivo_path)

    assert entry.revisions.empty?
  end

  test "with enable_local_sync we do write to a git repo and get history" do
    enable_local_sync do
      notebook = Notebook.create(name: "test")

      # still set to a temp dir tho
      arquivo_path = SyncWithGit.new(notebook).arquivo_path
      refute File.exist?(arquivo_path)
      refute arquivo_path.index("Documents")
      refute arquivo_path.index(ENV["HOME"])

      entry = notebook.entries.create(body: "foo")
      assert_equal 1, Entry.count

      # because local_sync is turned on,
      # we now get history from the repo
      assert File.exist?(arquivo_path)

      refute entry.revisions.empty?
    end
  end

  test "when an entry is updated, we write to a local repo" do
    notebook = Notebook.create(name: "test-notebook")
    enable_local_sync do
      # in the beginning, there is no folder
      arquivo_path = SyncWithGit.new(notebook).arquivo_path
      refute File.exist?(arquivo_path)

      entry = notebook.entries.create(body: "hello world")

      # but after the syncer runs, we gain an arquivo folder
      assert File.exist?(arquivo_path)

      # a notebook folder
      notebook_path = File.join(arquivo_path, notebook.name)
      assert File.exist?(notebook_path)

      # and this notebook is a git repo / has a .git folder
      git_repo_path = File.join(notebook_path, ".git")
      assert File.exist?(git_repo_path)

      # and now we can look up revisions

      assert_equal 1, entry.revisions.count

      # Great! Now when we edit an entry, revisions should get updated
      entry.update(body: "hello world v2")

      # we cache revisions, so we have to re-instantiate the whole object
      entry = Entry.find(entry.id)
      assert_equal 2, entry.revisions.count
    end
  end

  # TODO: we no longer invoke syncer from importer, this
  # whole test may be deprecated
  test "when we import a whole notebook, we create just one commit from the bulk import" do
    notebook = Notebook.create(name: "mynotebook")

    entries = create_list(:entry, 5, notebook: notebook)

    assert_equal 5, Entry.count
    assert_equal 1, Notebook.count

    enable_local_sync do |arquivo_path|
      SyncToDisk.new(notebook, arquivo_path).export!

      Entry.destroy_all
      assert_equal Entry.count, 0

      # now that we're set up, turn on git sync
      SyncFromDisk.import_all!(arquivo_path)
      SyncWithGit.new(notebook, arquivo_path).sync!(arquivo_path)

      # because this was triggered as an import,
      # we have only 1 commit, from the notebook import
      # (i.e. this isn't being fired on every Entry#save)
      repo_path = notebook.to_folder_path(arquivo_path)
      repo = Git.open(repo_path)
      assert_equal 1, repo.log.count
      assert repo.log.last.message.index("import from")

      assert_equal 5, Entry.count
    end
  end

  test "basic ffwd syncing between two notebooks using a bare repo in between" do
    notebook = Notebook.create(name: "test-notebook")

    temp_dirs = 3.times.map { Dir.mktmpdir }

    repo1_arquivo_path, repo2_arquivo_path, bare_arquivo_path = temp_dirs.map {|d| File.join(d, "arquivo") }
    test_arquivo_paths = [repo1_arquivo_path, repo2_arquivo_path, bare_arquivo_path]

    repo1_path, repo2_path, bare_repo_path = test_arquivo_paths.map { |d| File.join(d, "test-notebook") }

    # you dope, remember that each notebook is its own git repo not the arquivo folder as a whole
    begin
      enable_local_sync do
        bare_repo = Git.init(bare_repo_path, bare: true)

        repo1 = Git.init(repo1_path)
        repo1.add_remote("origin", bare_repo_path)

        repo2 = Git.init(repo2_path)
        repo2.add_remote("origin", bare_repo_path)

        # commit the notebook.yaml file
        # TODO: this whole interaction needs to be refactored
        SyncWithGit.new(notebook, repo1_arquivo_path).sync!("init")
        syncer1 = SyncWithGit.new(notebook, repo1_arquivo_path)
        entry = notebook.entries.create(body: "test entry",
                                        skip_local_sync: true)

        entry_identifier = entry.identifier

        syncer1.sync_entry!(entry)
        syncer1.push(notebook)

        # write_entry commit messages consist of the entry identifier
        assert_equal entry_identifier, bare_repo.log.first.message


        # the goal of this test is to pretend that we're syncing info back
        # and forth between diff arquivo installs.
        #
        # so when we pull on repo2 using syncer2 we will want the data being
        # imported to be reflected in the notebook. for that reason let's delete
        # the entry here:

        entry.destroy
        assert_equal 0, Entry.count

        # okay so now i want to pull the changes into repo2
        # using the local syncer

        syncer2 = SyncWithGit.new(notebook, repo2_arquivo_path)
        # TODO: should the syncer be responsible for importing? or do we do that as a separate step?
        syncer2.pull!

        # syncer just calls git pull under the hood
        # so we can look at the repo2 log to confirm the pull happened
        assert_equal entry_identifier, repo2.log.first.message

        assert_equal 1, Entry.count
        assert_equal entry_identifier, notebook.entries.last.identifier

        # TODO: need to keep track of sha pre and post pull
        # TODO: need to keep track of files being changed, so they can be imported
        # for now let's do the dumbest thing possible and re-import the whole fucking thing
        #
        # the annoying thing is that the Importer expects the arquivo path but we deal in the notebook path
      end
    ensure
      temp_dirs.each { |dir| FileUtils.remove_entry(dir) }
    end
  end

end
