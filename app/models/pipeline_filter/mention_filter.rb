# extended from the original in order to use our bespoke search path stuff
class PipelineFilter::MentionFilter < HTML::Pipeline::MentionFilter
  def link_to_mentioned_user(login)
    result[:mentioned_usernames] |= [login]

    "<a href='#{Rails.application.routes.url_helpers.search_path(notebook: context[:entry].notebook, query: "@#{login}")}' class='user-mention'>" \
      "@#{login}" \
      '</a>'
  end
end
