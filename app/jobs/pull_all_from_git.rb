class PullAllFromGit < ApplicationJob
  def perform()
    sleep(10)

    Arquivo.logger.debug "Pulling *all* from git."

    Notebook.find_each do |notebook|
      notebook.pull_from_git!
      Arquivo.logger.debug "not actually dying"
    end
    Arquivo.logger.debug "cheers mate"
  end
end

