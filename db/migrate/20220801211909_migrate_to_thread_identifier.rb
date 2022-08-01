class MigrateToThreadIdentifier < ActiveRecord::Migration[6.0]
  def change
    # on reflection this migration is Too Funky to run everywhere automatically
    # so i wanna avoid re-executing this multiple times & creating merge
    # random ass merge conflicts:
    return unless ENV["YES_REALLY_RUN_THIS"]

    Notebook.find_each do |notebook|
      # this will break if i ever change the Sync{With,To} interfaces
      # but otoh in the future it should no longer be possible to have a
      # non-null in_reply_to and a null thread_id
      if notebook.entries.where("in_reply_to is not null and thread_identifier is null").any?
        notebook.entries.where("in_reply_to is not null and thread_identifier is null").find_each do |entry|
          entry.skip_local_sync = true

          root_entry = entry

          # find root_entry, i.e. the entry with no parent
          # (since we're iterating thru the whole thread we could set the thread
          # identifier as we navigate the tree, but eh whatever)
          while root_entry.parent
            root_entry = root_entry.parent
          end

          entry.thread_identifier = root_entry.identifier
          entry.save!
        end

        git_syncer = SyncWithGit.new(notebook)
        git_syncer.git_adapter.with_lock do
          notebook.entries.where("in_reply_to is not null").find_each do |entry|
            unless Rails.application.config.skip_local_sync
              SyncToDisk.new(notebook).export_entry!(entry)
            end
          end

          repo = git_syncer.git_adapter.open_repo(notebook.to_folder_path)
          git_syncer.git_adapter.add_and_commit!(repo, notebook.to_folder_path, "MigrateToThreadIdentifier migration run.")
        end
      end
    end
  end
end
