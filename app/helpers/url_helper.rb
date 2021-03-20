module UrlHelper
  RailsUrlHelpers = Rails.application.routes.url_helpers

  def self.notebook_params(notebook)
    {
      owner: notebook.owner,
      notebook: notebook
    }
  end

  def self.entry_params(entry)
    notebook_params(entry.parent_notebook)
  end

  ["entry", "edit_entry"].each do |name|
    name_with_path = "#{name}_path".to_sym
    define_method name_with_path do |entry, opts = {}|
      RailsUrlHelpers.send(name_with_path, entry, opts.merge(UrlHelper.entry_params(entry)))
    end
  end

  ["new_entry", "timeline", "settings"].each do |name|
    name_with_path = "#{name}_path".to_sym
    define_method name_with_path do |notebook, opts = {}|
      RailsUrlHelpers.send(name_with_path, opts.merge(UrlHelper.notebook_params(notebook)))
    end
  end

  def copy_entry_path(entry, target_notebook, opts = {})
    RailsUrlHelpers.copy_entry_path(entry, target_notebook, opts.merge(UrlHelper.notebook_params(entry.parent_notebook)))
  end

  def calendar_daily_path(date, notebook, opts = {})
    RailsUrlHelpers.calendar_daily_path(date, opts.merge(UrlHelper.notebook_params(notebook)))
  end

  def calendar_weekly_path(notebook, opts = {})
    RailsUrlHelpers.calendar_weekly_path(opts.merge(UrlHelper.notebook_params(notebook)))
  end

  def calendar_path(notebook, opts = {})
    RailsUrlHelpers.calendar_path(opts.merge(UrlHelper.notebook_params(notebook)))
  end

  def search_path(notebook, opts = {})
    RailsUrlHelpers.search_path(opts.merge(UrlHelper.notebook_params(notebook)))
  end


    # def entry_path(entry, opts = {})
  #   RailsUrlHelpers.entry_path(entry, opts.merge(entry_params(entry)))
  # end
  #
  # def edit_entry_path(entry, opts = {})
  #   RailsUrlHelpers.new_entry_path(entry, opts.merge(entry_params(entry)))
  # end
  #
  # def new_entry_path(entry, opts = {})
  #
  # end

  # def timeline_path(notebook)
  #   Rails.application.routes.url_helpers.timeline_path(user: @current_user, notebook: notebook.name)
  # end
  #
  # def calendar_daily_path(date, notebook:)
  #   Rails.application.routes.url_helpers.calendar_daily_path(date, user: notebook.owner, notebook: notebook.name)
  # end
  #
  # def calendar_weekly_path(notebook:)
  #   Rails.application.routes.url_helpers.calendar_weekly_path(user: notebook.owner, notebook: notebook.name)
  # end
  #
  # def calendar_path(notebook:)
  #   Rails.application.routes.url_helpers.calendar_path(user: notebook.owner, notebook: notebook.name)
  # end
  #
  # def settings_path(notebook:)
  #   Rails.application.routes.url_helpers.settings_path(user: notebook.owner, notebook: notebook.name)
  # end
  #
  # def edit_entry_path(entry)
  #   Rails.application.routes.url_helpers.edit_entry_path(entry, user: entry.parent_notebook.owner, notebook: entry.parent_notebook.name)
  # end
  #
  # def new_entry_path(opts = {})
  #   Rails.application.routes.url_helpers.new_entry_path(opts.merge(user: opts[:notebook].owner, notebook: opts[:notebook].name))
  # end
  #
  # def entry_path(entry, opt = {})
  #   Rails.application.routes.url_helpers.entry_path(entry, opt.merge(notebook: entry.parent_notebook.name, user: entry.parent_notebook.owner))
  # end
  #
  # def search_path(query: "", notebook:)
  #   Rails.application.routes.url_helpers.search_path(query: query, notebook: notebook, user: notebook.owner)
  # end
end
