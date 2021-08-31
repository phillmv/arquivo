module StaticSite
  class StaticSiteController < ApplicationController
    before_action :prepend_custom_paths

    # This method is used for loading custom views provided by users to
    # override the default app templates.
    #
    # I wanted to the path exposed to be like,
    # `.site/views/entries/show.html.erb` but this caused issues given that
    # these controllers are prefixed with `static_site/`. Dropping the prefix
    # causes the `app/views/entries/` path to be loaded first, which contains
    # the non-static-site views.
    #
    # The solution therefore is to prepend the static_site view directly, so
    # `app/views/static_site/entries` will match before `app/views/entries`
    # will, and drop the `static_site` prefix from our `#controller_name`.
    #
    # We then prepend the current notebook's import path to load in the
    # appropriate files.
    def prepend_custom_paths
      prepend_view_path File.join(Rails.root, "app/views/static_site")
      prepend_view_path File.join(current_notebook.import_path || "", ".site/views/")
    end

    # This is used when generating URLs & overriding the default `localhost`
    # when booting in development mode / allowing the host to be configurable
    # since we're generating sites that will be hosted outside of the context
    # of this Rails app. This came up when writing the atom feeds.
    #
    # :site settings are provided via `.site/config.yaml`, see SyncFromDisk
    def default_url_options
      if host = current_notebook.settings.get(:host)
        # Here, we make sure to provide a port (default to 80) because otherwise
        # the route builders are """smart""" and use the request headers for
        # generating the different route fragments. In dev mode, I experienced
        # the request port being set to 3000, but I wanted my emitted URLs to
        # not include the url. By setting it to 80, the route helper is smart
        # enough to emit the example.com:port section.
        #
        # Naturally, this can also be overrided via `.site/config.yaml`
        { host: host, port: current_notebook.settings.get(:port) }
      else
        {}
      end
    end
  end
end
