require 'test_helper'

class CalendarImporterTest < ActiveSupport::TestCase
  setup do
    @cal_url = File.join(Rails.root, "test", "fixtures", "cal-t1.ics")
  end

  test "basic smoke test" do
    @ci = CalendarImport.create(notebook: "test", title: "example cal", url: @cal_url )

    assert_equal 0, ICalendarEntry.count
    importer = CalendarImporter.new(@ci)
    importer.process!

    assert_equal 34, ICalendarEntry.count
    assert_equal 13, ICalendarEntry.where(recurs: true).count
    assert_equal 6, ICalendarEntry.where("start_date is not null and start_time is null").count

    assert_equal "phillmv@example.com", ICalendarEntry.last.name
  end
end
