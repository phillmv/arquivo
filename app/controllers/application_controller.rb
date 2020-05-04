class ApplicationController < ActionController::Base
  before_action :current_notebook
  around_action :set_time_zone

  private

  def set_time_zone(&block)
    Time.use_zone(User.tz, &block)
  end

  def current_notebook
    notebook = params[:notebook] || session[:notebook] || Notebook.default

    @current_notebook = Notebook.find_by!(name: notebook).tap do
      session[:notebook] = notebook
    end
  end
end
