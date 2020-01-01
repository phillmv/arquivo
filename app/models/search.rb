class Search
  def self.find(query:, page: nil)
    Entry.where("body like ?", "%#{query}%").order(occurred_at: :desc)
  end
end
