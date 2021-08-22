atom_feed({'xmlns:app' => 'http://www.w3.org/2007/app',
           'xmlns:openSearch' => 'http://a9.com/-/spec/opensearch/1.1/'}) do |feed|
  feed.title("My great blog!") # TODO: grab from _somewhere_
  feed.updated((@all_entries.first.created_at))
  feed.tag!('openSearch:totalResults', 10)

  @all_entries.take(10).each do |post|
    feed.entry(post) do |entry|
      entry.title(post.subject)
      entry.content(EntryRenderer.new(post,).to_html, type: 'html')
      entry.tag!('app:edited', Time.now)

      entry.author do |author|
        author.name("example") # TODO: grab from entry?
      end
    end
  end
end
