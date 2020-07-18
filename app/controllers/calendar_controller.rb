class CalendarController < ApplicationController
  def monthly
    query_date = params[:start_date]&.to_datetime || Time.current

    start_date = query_date.beginning_of_month
    end_date = query_date.end_of_month

    @entries = Entry.where(notebook: @current_notebook.name).order(occurred_at: :desc).where("occurred_at >= ? and occurred_at <= ?", start_date, end_date)

  end

  def daily
    @date = params[:date].to_date
    start_date = @date.beginning_of_day
    end_date = @date.end_of_day

    @entries = Entry.where(notebook: @current_notebook.name).order(occurred_at: :desc).where("occurred_at >= ? and occurred_at <= ?", start_date, end_date)
  end

  def weekly
    query_date = params[:start_date]&.to_date || Time.current

    start_date = query_date.beginning_of_week
    end_date = query_date.end_of_week

    @entries = Entry.where(notebook: @current_notebook.name).visible.order(occurred_at: :desc).where("occurred_at >= ? and occurred_at <= ?", start_date, end_date)
  end
end
