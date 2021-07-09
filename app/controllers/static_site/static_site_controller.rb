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
  end
end
