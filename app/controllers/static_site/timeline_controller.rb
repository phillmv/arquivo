module StaticSite
  class TimelineController < StaticSiteController
    def index
      @all_entries = current_notebook.entries.visible.order(occurred_at: :desc).paginate(page: params[:page])

      @entries = @all_entries.group_by do |e|
        e.occurred_date
      end

      @colophon = current_notebook.entries.find_by(identifier: "colophon")
    end

    def archive
      @all_entries = current_notebook.entries.visible.order(occurred_at: :desc).paginate(page: params[:page])

      @entries = @all_entries.group_by do |e|
        e.occurred_date
      end
    end

    def feed
      @all_entries = current_notebook.entries.visible.order(occurred_at: :desc).limit(10)

      @feed_root_url = timeline_url
      @feed_id = timeline_feed_url
      @feed_title = current_notebook.settings.get(:title)
      @feed_updated_at = @all_entries.first&.occurred_at
      @author_name = current_notebook.settings.get(:author_name)

      render :atom
    end

    def tags
      @tags = current_notebook.tags.order(:name)
    end

    def tag
      @search_query = params[:query]
      @search_query = "##{@search_query}"
      compile_search(@search_query)
    end

    def tag_feed
      @search_query = params[:query]
      @search_query = "##{@search_query}"
      compile_search(@search_query)

      @feed_root_url = tag_url(params[:query])
      @feed_id = tag_feed_url(params[:query])
      @feed_title = current_notebook.settings.get(:title) + " (feed for #{@search_query})"
      @feed_updated_at = @all_entries.first&.occurred_at
      @author_name = current_notebook.settings.get(:author_name)

      render :atom
    end

    def contacts
      @contacts = current_notebook.contacts.order(:name)
    end

    def contact
      @search_query = params[:query]
      @search_query = "@#{@search_query}"
      compile_search(@search_query)
    end

    def contact_feed
      @search_query = params[:query]
      @search_query = "@#{@search_query}"
      compile_search(@search_query)

      @feed_root_url = contact_url(params[:query])
      @feed_id = contact_feed_url(params[:query])
      @feed_title = current_notebook.settings.get(:title) + " (feed for #{@search_query})"
      @feed_updated_at = @all_entries.first&.occurred_at
      @author_name = current_notebook.settings.get(:author_name)

      render :atom
    end

    def search
      @search_query ||= params[:query]
      if @search_query.present?

        compile_search(@search_query)

        render :index
      else
        redirect_to timeline_path(current_notebook)
      end
    end

    def hidden_entries
      @entries = current_notebook.entries.hidden.order(occurred_at: :asc).paginate(page: params[:page])
    end

    # drop `static_site/` prefix, see StaticSiteController#prepend_custom_paths
    def self.controller_path
      "timeline"
    end

    private
    def compile_search(query)
      search = Search.new(current_notebook)
      @all_entries = search.find(query: query).paginate(page: params[:page])

      @entries = @all_entries.group_by do |e|
        e.occurred_date
      end

      @has_todo = !!@search_query.index("has:todo")

      @search_tokens = search.tokens
    end
  end
end
