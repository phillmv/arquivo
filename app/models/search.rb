class Search
  FILTERS = Set.new([
    "is:calendar",
    "is:bookmark",
    "is:note",
    "not:note",
    "not:calendar",
    "not:bookmark",
  ])

  OPERATORS = [
    "before:",
    "after:"
  ]

  attr_reader :notebook
  def initialize(notebook)
    @notebook = notebook
  end

  def find(query:)
    tokens = []

    # super lazy quick way of doing this
    query.gsub(/"([^"]*)"/) do |match|
      tokens << match.gsub('"', '')
      ""
    end.split do |s|
      tokens << s
    end

    filters = []
    tokens = tokens.reject { |t| FILTERS.member?(t) && (filters << t) }

    operators = []
    tokens = tokens.reject do |t|
      OPERATORS.any? do |op|
        if (i = t.index(op)) && t[i+op.length + 1] !=~ /\s/
          operators << [op, t[i+op.length..-1]]
        else
          nil
        end
      end
    end

    sql_query = Entry.for_notebook(notebook).order(occurred_at: :desc)

    sql_where = tokens.map do |s|
      ["body like ? or subject like ?", "%#{s}%", "%#{s}%"]
    end

    sql_where.each do |where|
      sql_query = sql_query.where(*where)
    end

    filters.each do |op|
      sql_query = case op
      when "is:calendar"
        sql_query.calendars
      when "is:bookmark"
        sql_query.bookmarks
      when "is:note"
        sql_query.where("kind is null")
      when "not:calendar"
        sql_query.except_calendars
      when "not:bookmark"
        sql_query.except_bookmarks
      when "not:note"
        sql_query.where("kind is not null")
      end
    end

    operators.each do |op, arg|
      sql_query = case op
        when "before:"
          date = date_str_to_date(arg)
          sql_query.where("occurred_at < ?", date)
        when "after:"
          date = date_str_to_date(arg)
          sql_query.where("occurred_at >= ?", date)
      end
    end

    sql_query
  end

  def date_str_to_date(str)
     case str
     when "yesterday"
       Time.current.yesterday.end_of_day
     when "lastweek"
       6.days.ago.end_of_day
     when "lastmonth"
       Time.current.prev_month.end_of_month
     when "lastyear"
       Time.current.beginning_of_year
     else
       Time.zone.parse(str).beginning_of_day
     end
  end
end
