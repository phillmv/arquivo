class TimelineController < ApplicationController

  def index
    entries = Entry.order(occurred_at: :desc)
    @search_results = entries
    session[:search_query] = nil


    @entries = entries.group_by do |e|
      e.created_at.strftime("%Y-%m-%d")
    end
  end

  def search
    session[:search_query] = params[:searchfield]

    if session[:search_query].present?
      @search_query = session[:search_query]
      entries = Search.find(query: @search_query)

      @entries = entries.group_by do |e|
        e.created_at.strftime("%Y-%m-%d")
      end

      render :search
    else
      redirect_to timeline_path
    end
  end
end
