module ApplicationHelper
  SIDEBAR_NAV_OPTS = {
    "timeline/index" =>   :timeline,
    "timeline/search" =>  :timeline,
    "calendar/daily" =>   :timeline,
    "entries/show" =>     :timeline,
    "entries/new" =>      :timeline,
    "entries/edit" =>     :timeline,
    "calendar/daily" =>  :this_day,
    "calendar/weekly" =>  :this_week,
    "calendar/monthly" => :this_month,
    "settings/index" =>   :settings,
    "timeline/contacts" =>   :contacts,
    "timeline/contact" =>   :contacts,
    "timeline/tags" =>   :tags,
    "timeline/tag" =>   :tags,
  }

  def current_sidebar?(type)
    if SIDEBAR_NAV_OPTS[current_action] == type
      "text-purple"
    else
      nil
    end
  end

  #--- potentially deprecated
  def any_search_tabnav?(saved_searches, search_query)
    if saved_searches.none? { |ss| ss.query == search_query }
      "aria-current='page'"
    end
  end

  def search_tabnav(saved_search, search_query)
    if saved_search&.query == search_query
      "aria-current='page'"
    end
  end

  def search_tabnav_colour(saved_search, search_query)
    if search_tabnav(saved_search, search_query)
      "text-gray-dark"
    else
      "text-gray"
    end
  end
  # - end potential deprecation

  def current_search_tabnav(str, search)
    if str == search
      "aria-current='page'"
    end
  end

  def current_search_tabnav_colour(saved_search, search_query)
    if current_search_tabnav(saved_search, search_query)
      "text-gray-dark"
    else
      "text-gray"
    end
  end

  def current_action
    @current_action ||= "#{controller_name}/#{action_name}"
  end
end
