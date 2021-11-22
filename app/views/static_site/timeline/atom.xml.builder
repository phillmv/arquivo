atom_feed(id: @feed_id, root_url: @feed_root_url, url: @feed_id) do |feed|
  feed.title(@feed_title)
  feed.updated(@feed_updated_at)
  feed.author do |author|
    author.name(@author_name)
  end

  @all_entries.each do |post|
    feed.entry(post, {published: post.occurred_at, id: polymorphic_url(post, format: :html), url: polymorphic_url(post, format: :html)}) do |entry|
      entry.title(post.subject)
      entry.content(EntryRenderer.new(post).to_html, type: 'html')

      # ideally, grab author from entries
    end
  end
end
