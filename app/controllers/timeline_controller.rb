class TimelineController < ApplicationController

  def populate_search
    @search_query = session[:search_query]
    @search_results = Search.find(query: @search_query)
  end

  def index
    @entries = Entry.order(occurred_at: :desc)
    @search_results = @entries
    session[:search_query] = nil
  end

  def show
    populate_search
    @entry = Entry.find(params[:id])

    render :show
  end

  def search
    session[:search_query] = params[:searchfield]
    if session[:search_query].present?
      search_results = populate_search

      @entry = search_results.first
      render :show
    else
      redirect_to timeline_path
    end
  end
end
