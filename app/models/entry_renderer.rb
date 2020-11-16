require 'task_list/filter'
class EntryRenderer
  PIPELINE = PipelineFilter::ENTRY_PIPELINE

  attr_accessor :entry
  def initialize(entry)
    @entry = entry
  end

  # TODO: to_html should accept… a string, maybe?
  # not clear how this api should work.
  # should it accept: an attribute, a method, a full string?, a flag (i.e. :todo)
  # or just make everything a named keyword.

  def to_html(attribute_name = "body")
    attribute = entry.attributes[attribute_name]
    if !attribute
      ""
    else
      PIPELINE.to_html(attribute, entry: entry).html_safe
    end
  end

  # i don't love this - maybe this should be folded into #to_html
  # but for now this is easy to cache
  def todo_to_html
    @todo_to_html ||= PIPELINE.to_html(entry.body, entry: entry, todo_only: true).html_safe
  end

  def task_list_items
    PIPELINE.call(entry.body, entry: entry)[:task_list_items]
  end

  def gimme_html(str)
    PIPELINE.to_html(str, entry: entry).html_safe
  end
end
