class TimelineController < ApplicationController
  def index
    @entries = Entry.order(occurred_at: :desc)
  end

  def show
    @entry = Entry.find(params[:id])
    populate_search(params[:query])

    render :index
  end

  def search
    @entries = []
    populate_search(params[:query])
    if params[:entry_id].present?
      @entry = Entry.find(params[:entry_id])
    end
    render :index
  end

  def populate_search(query)
    if query.present?
      @search_entries = Entry.where("body like ?", "%#{query}%")
    else
      @search_entries = Entry.order(occurred_at: :desc)
    end
  end
end
