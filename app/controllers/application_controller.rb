class ApplicationController < ActionController::Base
  include UrlHelper
  before_action :current_notebook, :current_nwo, :set_recent_entries, :check_imports, :resync_with_remotes
  around_action :set_time_zone

  private

  def check_imports
    # don't do this too often?
    # feels silly to run the sql query on EVERY request, you know?
    last_checked_at = session[:checked_imports_at]
    if last_checked_at.nil? || last_checked_at < 6.hours.ago
      if CalendarImport.due_for_processing?
        UpdateCalendarsJob.perform_later
      end
      session[:checked_imports_at] = Time.current
    end
  end

  def resync_with_remotes
    last_checked_at = session[:synced_remotes_at]
    if last_checked_at.nil? || last_checked_at < 15.minutes.ago
      PullAllFromGit.perform_later
    end
    session[:synced_remotes_at] = Time.current
  end

  # def push_up
  #   last_pushed_at = session[:last_pushed_up_at]
  #
  #   if last_pushed_at.nil? || last_pushed_at < 1.hour.ago
  #     PushToGitJob.perform_later
  #   end
  # end

  def set_recent_entries
    @recent_entries = Entry.for_notebook(current_notebook).hitherto.visible.except_calendars.order(occurred_at: :desc).limit(10)
  end

  def set_time_zone(&block)
    Time.use_zone(User.tz, &block)
  end

  def current_user
    @current_owner ||= User.current
  end

  def current_nwo
    @current_nwo ||= "#{current_user}/#{current_notebook}"
  end

  # TODO: optimize
  def current_notebook
    if defined?(@current_notebook)
      return @current_notebook
    end

    notebook = params[:notebook] || session[:notebook] || Notebook.default

    @current_notebook = current_user.notebooks.find_by!(name: notebook).tap do
      session[:notebook] = notebook
    end
  end
end
