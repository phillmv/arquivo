module ApplicationHelper
  SIDEBAR_NAV_OPTS = {
    "timeline/index" =>   :timeline,
    "timeline/search" =>  :timeline,
    "entries/show" =>     :about,
    "calendar/daily" =>   :this_day,
    "calendar/weekly" =>  :this_week,
    "calendar/monthly" => :this_month,
    "settings/index" =>   :settings,
    "timeline/contacts" =>:contacts,
    "timeline/contact" => :contacts,
    "timeline/tags" =>    :tags,
    "timeline/tag" =>     :tags,
  }

  def current_sidebar?(type)
    match = SIDEBAR_NAV_OPTS[current_action] == type

    if match && type == :about
      if params[:id] == "about"
        "text-purple"
      else
        "text-blue"
      end
    elsif match
      "text-purple"
    else
      "text-blue"
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

  # https://coolors.co/f94144-f3722c-f8961e-f9844a-f9c74f-90be6d-43aa8b-4d908e-577590-277da1
  COLOURS1 = [
    "#f94144ff",
    "#f3722cff",
    "#f8961eff",
    "#f9844aff",
    "#f9c74fff",
    "#90be6dff",
    "#43aa8bff",
    "#4d908eff",
    "#577590ff",
    "#277da1ff",
  ]
  #
  # https://coolors.co/ff595e-ffca3a-8ac926-1982c4-6a4c93
  COLOURS2 = [
    "#ff595eff",
    "#ffca3aff",
    "#8ac926ff",
    "#1982c4ff",
    "#6a4c93ff",
  ]

  def tag_colour(tag)
    COLOURS1[tag.to_s.hash % COLOURS1.size]
  end
end
