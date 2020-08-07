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

    filters, tokens = parse_filters(tokens)
    operators, tokens = parse_operators(tokens)

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
                    sql_query.before(date)
                  when "after:"
                    date = date_str_to_date(arg)
                    sql_query.after(date)
                  end
    end

    sql_query
  end

  def parse_filters(tokens)
    filters = []
    tokens = tokens.reject { |t| FILTERS.member?(t) && (filters << t) }

    [filters, tokens]
  end

  def parse_operators(tokens)
    operators = []
    tokens = tokens.reject do |t|
      OPERATORS.any? do |op|
        # token t is a string "foo:bar"
        # if substring "foo:" exists, and the character following ':'
        # a) is not nil (i.e. the string continues past the operator)
        # b) is not whitespace
        if (i = t.index(op)) && not_nil_nor_whitespace?(t[i+op.length])
          operators << [op, t[i+op.length..-1]]
        else
          nil
        end
      end
    end

    [operators, tokens]
  end

  def not_nil_nor_whitespace?(char)
    !char.nil? && !char.match?(/\s/)
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
