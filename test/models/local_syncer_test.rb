require 'test_helper'

class LocalSyncerTest < ActiveSupport::TestCase
  test "without enable_local_sync we don't write to a git repo" do
    notebook = Notebook.create(name: "test")

    assert Rails.application.config.skip_local_sync

    arquivo_path = LocalSyncer.new.arquivo_path
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
      arquivo_path = LocalSyncer.new.arquivo_path
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
      arquivo_path = LocalSyncer.new.arquivo_path
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

  test "when we import a whole notebook, we create just one commit from the bulk import" do
    notebook = Notebook.create(name: "mynotebook")

    entries = create_list(:entry, 5, notebook: notebook)

    assert_equal 5, Entry.count
    assert_equal 1, Notebook.count

    enable_local_sync do

      Dir.mktmpdir do |export_import_path|
        Exporter.new(export_import_path).export!

        Entry.destroy_all
        assert_equal Entry.count, 0

        # now that we're set up, turn on git sync
        Importer.new(export_import_path).import!

        # because this was triggered as an import,
        # we have only 1 commit, from the notebook import
        # (i.e. this isn't being fired on every Entry#save)
        repo_path = File.join(Setting.get(:arquivo, :arquivo_path), "mynotebook")
        repo = Git.open(repo_path)
        assert_equal 1, repo.log.count
        assert repo.log.last.message.index("import from")

        assert_equal 5, Entry.count
      end
    ensure
      disable_local_sync
    end
  end

end
