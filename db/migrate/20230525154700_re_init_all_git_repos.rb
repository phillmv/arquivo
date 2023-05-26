class ReInitAllGitRepos < ActiveRecord::Migration[7.0]
  def change
    # with upgrade to rails 7, the git_defaults newest-wins script
    # had to be updated to safely load yaml files.
    # as a result, we have to re-copy the script to every notebook.
    Notebook.find_each do |notebook|
      notebook.initialize_git
    end
  end
end
