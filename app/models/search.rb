class Search
  OPERATORS = Set.new([
    "is:calendar",
    "is:bookmark",
    "not:calendar",
    "not:bookmark"
  ])
  def self.find(notebook:, query:, page: nil)
    tokens = []

    # super lazy quick way of doing this
    query.gsub(/"([^"]*)"/) do |match|
      tokens << match.gsub('"', '')
      ""
    end.split do |s|
      tokens << s
    end

    operators = []
    tokens = tokens.reject { |t| OPERATORS.member?(t) && (operators << t) }

    sql_query = Entry.for_notebook(notebook).order(occurred_at: :desc)

    sql_where = tokens.map do |s|
      ["body like ? or subject like ?", "%#{s}%", "%#{s}%"]
    end

    sql_where.each do |where|
      sql_query = sql_query.where(*where)
    end

    operators.each do |op|
      sql_query = case op
      when "is:calendar"
        sql_query.calendars
      when "is:bookmark"
        sql_query.bookmarks
      when "not:calendar"
        sql_query.except_calendars
      when "not:bookmark"
        sql_query.except_bookmarks
      end
    end

    sql_query
  end
end
