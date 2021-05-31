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

  ["threaded_entry", "entry", "edit_entry"].each do |name|
    name_with_path = "#{name}_path".to_sym
    define_method name_with_path do |entry, opts = {}|
      if Arquivo.static?
        RailsUrlHelpers.send(name_with_path, entry, opts.except(:notebook))
      else
        RailsUrlHelpers.send(name_with_path, entry, opts.merge(UrlHelper.entry_params(entry)))
      end
    end
  end

  ["new_entry", "timeline", "settings", "search", "calendar", "calendar_weekly"].each do |name|
    name_with_path = "#{name}_path".to_sym
    define_method name_with_path do |notebook, opts = {}|
      if Arquivo.static?
        RailsUrlHelpers.send(name_with_path, opts.except(:notebook))
      else
        RailsUrlHelpers.send(name_with_path, opts.merge(UrlHelper.notebook_params(notebook)))
      end
    end
  end

  def copy_entry_path(entry, target_notebook, opts = {})
    RailsUrlHelpers.copy_entry_path(entry, target_notebook, opts.merge(UrlHelper.notebook_params(entry.parent_notebook)))
  end

  def calendar_daily_path(date, notebook, opts = {})
    if Arquivo.static?
      RailsUrlHelpers.calendar_daily_path(date, opts)
    else
      RailsUrlHelpers.calendar_daily_path(date, opts.merge(UrlHelper.notebook_params(notebook)))
    end
  end
end
