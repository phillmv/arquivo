require 'test_helper'

class NotebookTest < ActiveSupport::TestCase
  test "filesystem_path is real" do
    notebook = Notebook.create(name: "testmctest")
    assert notebook.filesystem_path.index("arquivo/testmctest")
  end

  test "by default in test envs the filesystem path is a temp dir" do
    notebook = Notebook.create(name: "testmctest")
    assert Rails.application.config.skip_local_sync
    refute notebook.filesystem_path.index(ENV["HOME"])
    refute notebook.filesystem_path.index("Documents")
  end
end
