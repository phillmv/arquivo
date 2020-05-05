class Search
  def self.find(notebook:, query:, page: nil)
    tokens = []

    # super lazy quick way of doing this
    query.gsub(/"([^"]*)"/) do |match|
      tokens << match.gsub('"', '')
      ""
    end.split do |s|
      tokens << s
    end

    sql_where = tokens.map do |s|
      ["body like ? or subject like ?", "%#{s}%", "%#{s}%"]
    end

    sql_query = Entry.for_notebook(notebook).order(occurred_at: :desc)
    sql_where.each do |where|
      sql_query = sql_query.where(*where)
    end

    sql_query
  end
end
