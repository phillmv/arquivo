module StaticSite
  class StaticSiteController < ApplicationController
    before_action :prepend_paths

    def prepend_paths
      prepend_view_path File.join(current_notebook.import_path || "", ".site/views")
    end
  end
end
