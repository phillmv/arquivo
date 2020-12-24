require 'test_helper'

class LocalSyncerTest < ActiveSupport::TestCase
  setup do
    @notebook = Notebook.create(name: "test-notebook")
  end

  test "when an entry is updated, we write to a local repo" do

    begin
      enable_local_sync

      # in the beginning, there is no folder
      arquivo_path = LocalSyncer.new.arquivo_path
      refute File.exist?(arquivo_path)

      entry = @notebook.entries.create(body: "hello world")

      # but after the syncer runs, we gain an arquivo folder
      assert File.exist?(arquivo_path)

      # a notebook folder
      notebook_path = File.join(arquivo_path, @notebook.name)
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
    ensure
      disable_local_sync
    end
  end
end
