class CalendarController < ApplicationController
  def monthly
    query_date = params[:start_date]&.to_datetime || Time.current

    @start_date = query_date.beginning_of_month.beginning_of_day
    @end_date = query_date.end_of_month.end_of_day

    @entries = Entry.where(notebook: @current_notebook.name).order(occurred_at: :asc).where("occurred_at >= ? and occurred_at <= ?", @start_date, @end_date)

    @timeline_entries = @entries.paginate(page: params[:page])
    @grouped_entries = @timeline_entries.group_by do |e|
      e.occurred_date
    end

    @tags = tags_by_count(@start_date, @end_date)
    @contacts = contacts_by_count(@start_date, @end_date)
  end

  def daily
    if params[:date]
      @date = params[:date].to_date
    else
      @date = Date.today
    end

    @start_date = @date.beginning_of_day
    @end_date = @date.end_of_day

    @entries = Entry.where(notebook: @current_notebook.name).order(occurred_at: :asc).where("occurred_at >= ? and occurred_at <= ?", @start_date, @end_date)
  end

  def weekly
    query_date = params[:start_date]&.to_date || Time.current

    @start_date = query_date.beginning_of_week.beginning_of_day
    @end_date = query_date.end_of_week.end_of_day

    @entries = Entry.where(notebook: @current_notebook.name).visible.order(occurred_at: :asc).where("occurred_at >= ? and occurred_at <= ?", @start_date, @end_date)

    @timeline_entries = @entries.paginate(page: params[:page])
    @grouped_entries = @timeline_entries.group_by do |e|
      e.occurred_date
    end

    @tags = tags_by_count(@start_date, @end_date)
    @contacts = contacts_by_count(@start_date, @end_date)
  end

  def tags_by_count(start_date, end_date)
    entries_between(start_date, end_date).joins(:tags).group("tags.name").count.sort_by { |k,v| -v }
  end

  def contacts_by_count(start_date, end_date)
    entries_between(start_date, end_date).joins(:contacts).group("contacts.name").count.sort_by { |k,v| -v }
  end

  def entries_between(start_date, end_date)
    current_notebook.entries.after(start_date).before(end_date)
  end
end
