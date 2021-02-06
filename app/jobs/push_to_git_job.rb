class PushToGitJob < ApplicationJob
  def perform(notebook_id)
    # running this in dev env locally using the async adapter,
    # if i don't include sleep(10), despite being perform_later'ed, this job
    # will execute within the request and the request will take ~3s as this
    # pings the git remote.
    #
    # BUT if I include a sleep(10), the request returns immediately (~100ms)
    # and then 10 seconds later the job fires.
    #
    # this is obviously a bug or a misconfiguration or i'm doing something silly
    # but i have so little free time i cannot be arsed to care about figuring
    # this out right now. weird! but for now eh okay fine, computers are bad.
    sleep(10)
    notebook = Notebook.find(notebook_id)
    # TODO: log if errors exist, figure out when to pull
    notebook.push_to_git!
  end
end
