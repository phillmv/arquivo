class ApplicationController < ActionController::Base
  before_action :current_notebook, :set_recent_entries
  around_action :set_time_zone

  private

  def set_recent_entries
    @recent_entries = Entry.for_notebook(current_notebook).hitherto.visible.except_calendars.order(occurred_at: :desc).limit(10)
  end

  def set_time_zone(&block)
    Time.use_zone(User.tz, &block)
  end

  # TODO: optimize
  def current_notebook
    notebook = params[:notebook] || session[:notebook] || Notebook.default

    @current_notebook = Notebook.find_by!(name: notebook).tap do
      session[:notebook] = notebook
    end
  end
end
