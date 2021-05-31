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

  # TODO: i feel like this method could be simplified / some of its concerns
  # could be shifted to the `redirect_to_notebook` controller method
  def current_notebook
    if defined?(@current_notebook)
      return @current_notebook
    end

    # remember the last notebook we were on, so we can redirect to it
    # if we're visiting the root route
    notebook_name = ENV["notebook_name"] || params[:notebook] || session[:notebook_name]
    if notebook_name
      @current_notebook = current_user.notebooks.find_by!(name: notebook_name).tap do
        session[:notebook_name] = notebook_name
      end
    else
      @current_notebook = nil
    end
  end
end
