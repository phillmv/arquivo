module ApplicationHelper
  TABNAV_OPTS = {
    "timeline/index" => :timeline,
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

  def current_action
    @current_action ||= "#{controller_name}/#{action_name}"
  end
end
