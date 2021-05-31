# extended from the original in order to use our bespoke search path stuff
class PipelineFilter::MentionFilter < HTML::Pipeline::MentionFilter
  def link_to_mentioned_user(login)
    result[:mentioned_usernames] |= [login]

    link_path = nil
    if Arquivo.static?
      link_path = Rails.application.routes.url_helpers.search_path(query: "@#{login}")
    else
      link_path = Rails.application.routes.url_helpers.search_path(owner: context[:entry].parent_notebook.owner, notebook: context[:entry].notebook, query: "@#{login}")
    end

    "<a href='#{link_path}' class='user-mention'>" \
      "@#{login}" \
      '</a>'
  end
end
