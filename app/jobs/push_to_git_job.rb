class PushToGitJob < ApplicationJob
  def perform(notebook_id)
    notebook = Notebook.find(notebook_id)
    # TODO: log if errors exist, figure out when to pull
    notebook.push_to_git!
  end
end
