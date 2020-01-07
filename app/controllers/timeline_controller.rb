class TimelineController < ApplicationController

  def index
    entries = Entry.order(occurred_at: :desc)
    @search_results = entries
    session[:search_query] = nil


    @entries = entries.group_by do |e|
      e.created_at.strftime("%Y-%m-%d")
    end
  end

  def show
    @search_query = session[:search_query]
    if @search_query.present?
      @search_results = Search.find(query: @search_query)
    else
      @search_results = Entry.order(occurred_at: :desc)
    end

    @entry = Entry.find(params[:id])

    render :show
  end

  def search
    session[:search_query] = params[:searchfield]

    if session[:search_query].present?
      @search_query = session[:search_query]
      @search_results = Search.find(query: @search_query)

      @entry = @search_results.first
      render :show
    else
      redirect_to timeline_path
    end
  end
end
