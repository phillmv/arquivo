require 'test_helper'

class SearchTest < ActiveSupport::TestCase
  setup do
    @notebook = Notebook.create(name: "main")
    @other_notebook = Notebook.create(name: "other")

    @hello_world = @notebook.entries.create(body: "hello world!")
    @goodbye_world = @notebook.entries.create(body: "goodbye cruel world!")

    @other_hello_world = @other_notebook.entries.create(body: "hello world!")

    @notebook.entries.create(body: "#test #great\nyo yo yo")
    @notebook.entries.create(body: "#test2 #great\nsecond list")

    @calendar_entry = @notebook.entries.calendars.create(subject: "grocery list", body: "#meeting @lisa\nhi hi hi")
    # TODO: LOL should also search urls, eh?
    @bookmark_entry = @notebook.entries.bookmarks.create(subject: "sample link!", url: "http://example.com/sample", body: "#cool #interesting")

    @before_entries = [
      @notebook.entries.create(body: "a long long time ago", occurred_at: "1959-01-31"),
      @notebook.entries.create(body: "i can still remember", occurred_at: "1959-02-01"),
      @notebook.entries.create(body: "that music used to make me smile", occurred_at: "1959-02-02")
    ]


    @after_entries = [
      @notebook.entries.create(body: "when i read about his widowed bride", occurred_at: "1959-02-03"),
      @notebook.entries.create(body: "something touched me deep inside", occurred_at: "1959-02-03"),
      @notebook.entries.create(body: "the day the music died", occurred_at: "1959-02-03")
    ]
  end

  test "smoke test search" do
    result = Search.new(@notebook).find(query: "hello")

    refute_equal result.size, @notebook.entries.size
    assert_equal 1, result.size
    assert_equal @hello_world, result.first

    # by default does not discriminate between types,
    # also searches the subject field
    result = Search.new(@notebook).find(query: "grocery list")

    assert_equal @calendar_entry, result.first
  end

  test "searches in one notebook but not another" do
    result = Search.new(@other_notebook).find(query: "hello")

    assert_equal result.size, @other_notebook.entries.size
    assert_equal 1, result.size
    refute_equal result.first, @hello_world
    assert_equal result.first, @other_hello_world
  end

  test "searches within strings" do
    result = Search.new(@notebook).find(query: "llo")

    assert_equal @hello_world, result.first
  end

  test "handles hashtags and names" do
    result = Search.new(@notebook).find(query: "#great")

    assert_equal 2, result.size

    result = Search.new(@notebook).find(query: "@lisa")
    assert_equal 1, result.size
  end

  test "multiple search tokens AND together" do
    result = Search.new(@notebook).find(query: "world")
    # should find "hello world" and "goodbye cruel world"
    assert_equal 2, result.size

    result = Search.new(@notebook).find(query: "world goodbye")

    # if search tokens ORed together, i would expect
    # this to return both hello and goodbye cruel world
    assert_equal 1, result.size
    assert_equal @goodbye_world, result.first
  end

  test "handles filters" do
    # --- calendars
    #
    result = Search.new(@notebook).find(query: "is:calendar")

    assert_equal 1, result.size
    assert_equal @calendar_entry, result.first

    result = Search.new(@notebook).find(query: "not:calendar")
    refute result.any? { |r| r.calendar? }

    # --- bookmarks

    result = Search.new(@notebook).find(query: "is:bookmark")

    assert_equal 1, result.size
    assert_equal @bookmark_entry, result.first

    result = Search.new(@notebook).find(query: "not:bookmark")
    refute result.any? { |r| r.bookmark? }

    # --- notes

    result = Search.new(@notebook).find(query: "is:note")
    assert result.all? { |r| r.note? }

    result = Search.new(@notebook).find(query: "not:note")
    refute result.any? { |r| r.note? }

    # filters can be combined with search
    result = Search.new(@notebook).find(query: "is:note #great")

    assert_equal 2, result.size
    assert result.all?(&:note?)

    result = Search.new(@notebook).find(query: "not:note #great")

    assert_equal 0, result.size

    # positive filters are mutually exclusive

    result = Search.new(@notebook).find(query: "is:note is:calendar")
    assert_equal 0, result.size

    # negative filters can be combined

    result = Search.new(@notebook).find(query: "not:note not:calendar")
    assert_equal 1, result.size
    assert_equal @bookmark_entry, result.first
  end

  test "handles operators" do
    results = Search.new(@notebook).find(query: "before:1959-02-03")

    assert_equal 3, results.size
    assert_equal @before_entries.to_set, results.to_set


    results = Search.new(@notebook).find(query: "after:1959-02-03 before:1960-01-01")

    assert_equal 3, results.size
    assert_equal @after_entries.to_set, results.to_set
  end
end

