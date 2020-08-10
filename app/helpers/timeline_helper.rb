module TimelineHelper
  def truncate_class(entry, collapsed = false)
    if (entry.body&.size || 0) > 1024 && !collapsed
      " truncate"
    else
      ""
    end
  end
end
