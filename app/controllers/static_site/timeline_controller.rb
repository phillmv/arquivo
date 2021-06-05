module StaticSite
  class TimelineController < ApplicationController
    def index
      @all_entries = current_notebook.entries.visible.hitherto.order(occurred_at: :desc).paginate(page: params[:page])

      @entries = @all_entries.group_by do |e|
        e.occurred_date
      end
    end

    def tags
      @search_query = params[:query]
      @search_query = "##{@search_query}"
      search()
    end

    def contacts
      @search_query = params[:query]
      @search_query = "@#{@search_query}"
      search()
    end

    def search
      @search_query ||= params[:query]

      search = Search.new(current_notebook)

      if @search_query.present?
        @all_entries = search.
          find(query: @search_query).paginate(page: params[:page])

        @entries = @all_entries.group_by do |e|
          e.occurred_date
        end

        @has_todo = !!@search_query.index("has:todo")

        @search_tokens = search.tokens

        render :index
      else
        redirect_to timeline_path(current_notebook)
      end
    end
  end
end
