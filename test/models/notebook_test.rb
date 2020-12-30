require 'test_helper'

class NotebookTest < ActiveSupport::TestCase
  test "to_folder_path works as intended" do
    notebook = Notebook.create(name: "testmctest")
    assert notebook.to_folder_path.index("arquivo/testmctest")
  end

  test "by default in test envs the filesystem path is a temp dir" do
    notebook = Notebook.create(name: "testmctest")
    assert Rails.application.config.skip_local_sync
    refute notebook.to_folder_path.index(ENV["HOME"])
    refute notebook.to_folder_path.index("Documents")
  end
end
