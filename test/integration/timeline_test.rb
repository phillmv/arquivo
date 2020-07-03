require 'test_helper'

class TimelineTest < ActionDispatch::IntegrationTest
  setup do
    @current_notebook = Notebook.create(name: "test")
    # stub out User tz so we enforce UTC for tests
    def User.tz
      "UTC"
    end

    @yesterday = 1.day.ago.beginning_of_day
    [@yesterday, @yesterday - 1.day, @yesterday - 2.days].each do |date|
      5.times do
        create(:entry, occurred_at: (date + rand(1000).minutes))
      end
    end

    20.times do
      create(:entry, occurred_at: (5.days.ago + rand(100).minutes))
    end

    @calendar_entry = create(:entry, :calendar, occurred_at: @yesterday + 3.hours)
  end

  test "timeline smoke test" do
    get timeline_path(notebook: "test")
    assert_response :success

    # entries split across three days
    assert_select ".entry-date h3 a", @yesterday.strftime("%Y-%m-%d")
    assert_select ".entry-date h3 a", (@yesterday - 1.day).strftime("%Y-%m-%d")
    assert_select ".entry-date h3 a", (@yesterday - 2.days).strftime("%Y-%m-%d")

    # we display a calendar entry
    assert_select ".calendar-entry h3 a", @calendar_entry.subject

    # goes over the max page limit, so:
    assert_select ".pagination"

    # let's ensure we at least link to the show and edit page of each entry

    entry_links = css_select(".entry-list-header a").map { |e| e["href"].presence }.compact.to_set

    # entries guaranteed to be on the first page
    first_page_entries =  Entry.where("occurred_at > ?", 4.days.ago).where("kind is null or kind != ?", "calendar")
    assert_equal 15, first_page_entries.size

    first_page_entries.each do |entry|
      assert entry_links.include?(entry_path(entry, notebook: entry.notebook))
      assert entry_links.include?(edit_entry_path(entry, notebook: entry.notebook))
    end

    # but obv stuff not in the first page won't show up
    page2_entry = Entry.order(occurred_at: :desc).last
    refute entry_links.include?(entry_path(page2_entry, notebook: page2_entry.notebook))

    # last but not least let's get page 2 eh
    get timeline_path(notebook: "test", page: 2)
    assert_response :success
  end
end
