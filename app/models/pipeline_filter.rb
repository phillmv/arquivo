module PipelineFilter
  # we just want to tweak the default whitelist a little bit
  # and allow the data-sourcepos attribute to go thru
  ENTRY_SANITIZATION_WHITELIST = HTML::Pipeline::SanitizationFilter::WHITELIST.dup
  ESW = ENTRY_SANITIZATION_WHITELIST
  ESW[:attributes] = ESW[:attributes].dup
  ESW[:attributes][:all] = ESW[:attributes][:all].dup
  ESW[:attributes][:all].push("data-sourcepos")

  TODO_SANITIZATION_WHITELIST = ENTRY_SANITIZATION_WHITELIST.dup
  TSW = TODO_SANITIZATION_WHITELIST

  # The Todo render pipeline is the same as the Entry pipeline, but we run
  # a second sanitization step after the TaskFilter.

  # We attach a transformer lambda that checks wipes out non-list tags, and
  # checks lists to see if they have been given the task list class

  # We have to run the sanitization filter twice because the TaskFilter introduces
  # input fields, which would be otherwise removed. We can't 
  TSW[:elements] = TSW[:elements] + %w[input]
  TSW[:attributes] = TSW[:attributes].dup
  TSW[:attributes]['input'] = ['class']
  TSW[:attributes]['ul'] = ['class']
  TSW[:attributes]['ol'] = ['class']
  TSW[:attributes]['li'] = ['class']

  TOP_LEVEL_TAGS = %w[p blockquote h1 h2 h3 h4 h5 h6 hr pre].to_set

  TSW[:transformers] = [
    # this almost certainly can just be replaced with a filter
    # or by adding it to the task filter?
    lambda do |env|
      name = env[:node_name]
      node = env[:node]

      if ["ul","ol"].include?(name)
        if node.attributes["class"]&.value != "task-list"
          node.remove
        end
      elsif name == "li"
        if node.attributes["class"]&.value != "task-list-item"
          node.remove
        end
      elsif TOP_LEVEL_TAGS.include?(name) && node.ancestors.first&.name == "#document-fragment"
        node.remove
      end
    end
  ].freeze
end
