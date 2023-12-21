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
        # A year and a half later, I don't remember _why_ I started forcing
        # .html urls in links (isn't this breaking document downloads?)
        # my impression is I made this distinction in order to force
        # downloaded urls to be stored with .html extension so they can
        # be served statically – but i'm not entirely sure this is The Correct Way
        these_opts = opts.except(:notebook)
        if entry.append_html_extension?
          these_opts = these_opts.merge(format: "html")
        end
        RailsUrlHelpers.send(name_with_path, entry, these_opts)
      else
        RailsUrlHelpers.send(name_with_path, entry, opts.merge(UrlHelper.entry_params(entry)))
      end
    end
  end

  ["new_entry", "timeline", "settings", "search", "calendar", "calendar_weekly"].each do |name|
    name_with_path = "#{name}_path".to_sym
    define_method name_with_path do |notebook, opts = {}|
      if Arquivo.static?
        RailsUrlHelpers.send(name_with_path, opts.except(:notebook).merge(format: "html"))
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
      RailsUrlHelpers.calendar_daily_path(date, opts.merge(format: "html"))
    else
      RailsUrlHelpers.calendar_daily_path(date, opts.merge(UrlHelper.notebook_params(notebook)))
    end
  end
end
