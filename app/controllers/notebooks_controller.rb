class NotebooksController < ApplicationController

  def tags

    query = Tag.where(notebook: @current_notebook.name).order(updated_at: :desc).limit(8).select(:id, :name)
    if params[:query]
      query = query.where("name like ?", "%#{params[:query]}%")
    end

    render json: query
  end

  def contacts
    query = Contact.where(notebook: @current_notebook.name).order(updated_at: :desc).limit(8).select(:id, :name)
    if params[:query]
      query = query.where("name like ?", "%#{params[:query]}%")
    end

    render json: query
  end

  def update
    if params[:colours]
      colour = nil;
      case params[:colours]
      when { "blue" => "on" }
        colour = "#0366d6"
      when { "red" => "on" }
        colour = "#d80303"
      when { "purple" => "on" }
        colour = "purple"
      end

      if colour
        current_notebook.colour = colour
        current_notebook.save!
      end
    end

    redirect_to settings_path(notebook: current_notebook)
  end
end
