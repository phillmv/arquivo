module ApplicationHelper
  TABNAV_OPTS = {
    "timeline/index" => :timeline,
    "timeline/search" => :timeline,
    "timeline/agenda" => :this_day,
    "calendar/weekly" => :this_week,
    "calendar/monthly" => :this_month,
  }
  def current_tabnav(opt)
    if TABNAV_OPTS[current_action] == opt
      "aria-current='page'"
    else
      nil
    end
  end

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

  def current_action
    @current_action ||= "#{controller_name}/#{action_name}"
  end
end
