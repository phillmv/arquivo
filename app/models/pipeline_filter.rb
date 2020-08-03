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
  # a second sanitization step after the TaskFilter. There is a 2-step trick here:
  #
  # 1. Because Commonmarker wraps everything in a <p> tag, by exclusing the p tag
  # from the allowed elements, we delete virtually all html that is not in a list
  #
  # 2. We attach a transformer lambda that checks list tags to see if they have
  # been given the task list class.
  TSW[:elements] = TSW[:elements] - %w[p blockquote h1 h2 h3 h4 h5 h6 hr pre]
  TSW[:remove_contents] = %w[p pre h1 h2 h3 h4 h5 h6]

  # this is why we have to run the sanitization filter twice:
  # the TaskFilter introduces input fields, which would be otherwise removed.
  # Because we've already sanitized this once, we can be assured this
  # whitelisted input actually came from the TaskFilter
  TSW[:elements] = TSW[:elements] + %w[input]
  TSW[:attributes] = TSW[:attributes].dup
  TSW[:attributes]['input'] = ['class']
  TSW[:attributes]['ul'] = ['class']
  TSW[:attributes]['ol'] = ['class']
  TSW[:attributes]['li'] = ['class']
  TSW[:transformers] = [
    lambda do |env|
      name = env[:node_name]
      node = env[:node]

      if ["ul","ol"].include?(name)
        if node.attributes["class"].present? && node.attributes["class"].value == "task-list"
        else
          node.remove
        end
      end
    end
  ].freeze

  # TODO: handle p nested inside a list, handle lis without the task list class. might have to make a lambda for all of this

end
