class ApplicationController < ActionController::Base
  before_action :current_notebook, :set_recent_entries, :check_imports
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

  def set_recent_entries
    @recent_entries = Entry.for_notebook(current_notebook).hitherto.visible.except_calendars.order(occurred_at: :desc).limit(10)
  end

  def set_time_zone(&block)
    Time.use_zone(User.tz, &block)
  end

  # TODO: optimize
  def current_notebook
    if defined?(@current_notebook)
      return @current_notebook
    end

    notebook = params[:notebook] || session[:notebook] || Notebook.default

    @current_notebook = Notebook.find_by!(name: notebook).tap do
      session[:notebook] = notebook
    end
  end
end
