class Search
  def self.find(notebook:, query:, page: nil)
    Entry.for_notebook(notebook).where("body like ?", "%#{query}%").order(occurred_at: :desc)
  end
end
