module TimelineHelper
  def truncate_class(entry, collapsed = false)
    if collapsed
      if (entry.body&.size || 0) > 180
      "truncate truncate-more"
      else
        ""
      end
    elsif(entry.body&.size || 0) > 768
      "truncate"
    else
      ""
    end
  end
end
