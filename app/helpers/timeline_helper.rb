module TimelineHelper
  def truncate_class(entry_body, collapsed = false)
    if collapsed
      if (entry_body&.size || 0) > 220
      "truncate truncate-more"
      else
        ""
      end
    elsif(entry_body&.size || 0) > 1024
      "truncate"
    else
      ""
    end
  end
end
