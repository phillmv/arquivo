class ApplicationController < ActionController::Base
  before_action :current_notebook

  def current_notebook
    @current_notebook ||= Notebook.find_by!(name: params[:notebook])
  end
end
