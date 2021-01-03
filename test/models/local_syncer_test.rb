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

  # this test asserts that:
  # a) we can push and pull from remote repos, and our Entry objects will auto update
  # b) in case of conflict, it will still work seamlessly
  test "basic ffwd syncing between two notebooks using a bare repo in between" do
    notebook = Notebook.create(name: "test-notebook")

    # we keep these vars around so we can ensure they're deleted.
    temp_dirs = 3.times.map { Dir.mktmpdir }

    test_arquivo_paths = temp_dirs.map {|d| File.join(d, "arquivo") }
    repo1_arquivo_path, repo2_arquivo_path, bare_arquivo_path = test_arquivo_paths

    repo1_path, repo2_path, bare_repo_path = test_arquivo_paths.map { |d| File.join(d, "test-notebook") }

    begin
      bare_repo = Git.init(bare_repo_path, bare: true)

      repo1 = Git.init(repo1_path)
      repo1.add_remote("origin", bare_repo_path)

      repo2 = Git.init(repo2_path)
      repo2.add_remote("origin", bare_repo_path)

      # (TODO: this interaction needs to be refactored; init! should prob commit the notebook.yaml file)
      syncer1 = SyncWithGit.new(notebook, repo1_arquivo_path)
      syncer1.init!
      # commit the notebook.yaml file, which should happen automatically somehow, see above re: refactoring
      syncer1.sync!

      # first we create our sample entry and push it out
      entry = notebook.entries.create(body: "test entry")
      entry_identifier = entry.identifier
      entry_attr = entry.export_attributes

      syncer1.sync_entry!(entry)
      syncer1.push

      # individual entry commit messages consist of the entry identifier,
      # which we verify here:
      assert_equal entry_identifier, bare_repo.log.first.message


      # the goal of this test is to pretend that we're syncing info back
      # and forth between diff arquivo installs.
      #
      # so when we pull on repo2 using syncer2 we will want the data being
      # imported to be reflected in the notebook. for that reason, let's delete
      # the entry here:

      entry.destroy
      assert_equal 0, Entry.count

      # okay so now we have a "pristine" database, and i want to pull the
      # content in repo1 into repo2, and have that be reflected in my db

      syncer2 = SyncWithGit.new(notebook, repo2_arquivo_path)
      syncer2.pull!

      # syncer just calls git pull under the hood
      # so we can look at the repo2 log to confirm the pull happened
      assert_equal entry_identifier, repo2.log.first.message

      assert_equal 1, Entry.count
      assert_equal entry_attr, notebook.entries.last.export_attributes

      # Great, we've established that we can push an entry from repo1 to repo2
      # and get a new Entry out of it.
      #
      # However, this was the easy case. What if there's a conflict?
      #
      # Let's create some diverging history between the two repos via series of
      # incompatible updates to the entry.

      # Since we're "in" the repo2 context, let's create some entries and
      # commits here:
      entry = notebook.entries.last
      entry.update(body: "tesr emtry")
      syncer2.sync_entry!(entry)
      entry.update(body: "tess emtsy")
      syncer2.sync_entry!(entry)

      repo2_entry_attr = entry.attributes

      # Meanwhile in repo1, we've been making incompatible changes:
      entry.update(body: "TEST ENTRY")
      syncer1.sync_entry!(entry)
      entry.update(body: "MY TEST ENTRY!!!")
      syncer1.sync_entry!(entry)
      syncer1.push

      repo1_entry_attr = entry.attributes

      # Cool. Let's pull the changes in repo1 into repo2. In order to simulate
      # the process across two different installs, let's once again reset the
      # entry (databse) content to be in the syncer2 state we last left it in:
      entry.update(repo2_entry_attr)
      assert_equal entry.reload.attributes, repo2_entry_attr

      # We're now in repo2's context, and we're about to pull the changes
      # pushed in from repo1.

      # The goal here is to have SyncWithGit:
      # 1. fetch into repo2 the changes from repo1 that were pushed to the bare repo
      # 2. since these entries conflict, choose the most recent version
      #   i.e. "MY TEST ENTRY!!!" (this should happen invisibly from this test's
      #   perspective)
      # 3. load the current version from disk into the database, thereby updating the entry

      syncer2.pull!

      refute_equal entry.reload.attributes, repo2_entry_attr
      assert_equal entry.reload.attributes, repo1_entry_attr

      # TODO: what about files that get deleted?
      # TODO: verify the config gets setup, somehow
      # TODO: is there some way to ensure the script gets run?
      # TODO: Shit there was something else that was important to assert but what was it???
      # TODO: Oh, assert that the previous version still exists in its history!!!
      # TODO: need to keep track of sha pre and post pull? Need to know which files get changed
    ensure
      temp_dirs.each { |dir| FileUtils.remove_entry(dir) }
    end
  end

end
