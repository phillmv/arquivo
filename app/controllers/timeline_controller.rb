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

  def calendar
    query_date = params[:start_date]&.to_date || Time.zone.now

    start_date = query_date.beginning_of_month
    end_date = query_date.end_of_month

    @entries = Entry.order(occurred_at: :desc).where("occurred_at >= ? and occurred_at <= ?", start_date, end_date)
  end
end
