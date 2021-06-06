class TestPull < ApplicationJob
  def perform
    sleep(10)

    n = Notebook.for("copy-of-work")
    SyncFromDisk.new(n.to_folder_path).import!
  end
end
