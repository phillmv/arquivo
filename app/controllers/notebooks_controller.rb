class NotebooksController < ApplicationController

  def tags

    query = Tag.where(notebook: @current_notebook.name).order(updated_at: :desc).limit(8).select(:id, :name)
    if params[:query]
      query = query.where("name like ?", "%#{params[:query]}%")
    end

    render json: query
  end
end
