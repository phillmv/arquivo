class TimelineController < ApplicationController
  def redirect_to_notebook
    notebook = current_notebook || current_user.notebooks.first

    if notebook
      redirect_to timeline_path(notebook)
    else
      render text: "i need to set this up! create a notebook pls"
    end
  end

  def index
    @title = "Timeline"

    @all_entries = Entry.for_notebook(current_notebook).notes.visible.hitherto.
      order(occurred_at: :desc).paginate(page: params[:page])

    @entries = @all_entries.group_by do |e|
      e.occurred_date
    end
  end

  def search
    @search_query = params[:query]
    search = Search.new(current_notebook)

    @title = "Search for #{@search_query}"

    if @search_query.present?
      @all_entries = search.
        find(query: @search_query).paginate(page: params[:page])

      @entries = @all_entries.group_by do |e|
        e.occurred_date
      end

      @display_todos_only = !!@search_query.index("only:todo")

      @search_tokens = search.tokens

      render :index
    else
      redirect_to timeline_path(current_notebook)
    end
  end

  def save_search
    SavedSearch.transaction do
      saved_search = current_notebook.saved_searches.find_by(name: saved_search_params[:name])
      if saved_search
        saved_search.update(saved_search_params)
      else
        current_notebook.saved_searches.create(saved_search_params)
      end
    end

    redirect_to search_path(current_notebook, query: params[:saved_search][:query])
  end

  def delete_saved_search
    saved_search =current_notebook.saved_searches.find(params[:id])

    if saved_search
      saved_search.destroy
    end

    redirect_to timeline_path(current_notebook)
  end

  def saved_search_params
    params.require(:saved_search).permit(:name, :query, :octicon)
  end
end
