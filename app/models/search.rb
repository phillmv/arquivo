class Search
  def self.find(query:, page: nil)
    Entry.where("body like ?", "%#{query}%")
  end
end
