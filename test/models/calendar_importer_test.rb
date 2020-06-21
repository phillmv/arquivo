require 'test_helper'

class CalendarImporterTest < ActiveSupport::TestCase
  setup do
    @cal_url = File.join(Rails.root, "test", "fixtures", "sample_cal_20200530.ics")
    @cal_url2 = File.join(Rails.root, "test", "fixtures", "sample_cal_20200620.ics")
  end

  test "basic smoke test" do
    @ci = CalendarImport.create(notebook: "test", title: "example cal", url: @cal_url)

    refute @ci.last_imported_at

    assert_equal 0, ICalendarEntry.count
    importer = CalendarImporter.new(@ci)
    importer.process!

    assert_equal 34, ICalendarEntry.where(calendar_import: @ci).count
    assert_equal 13, ICalendarEntry.where(calendar_import: @ci, recurs: true).count
    assert_equal 6, ICalendarEntry.where(calendar_import: @ci).
      where("start_date is not null and start_time is null").count

    assert_equal "phillmv@example.com", ICalendarEntry.last.name

    t1_import = @ci.reload.last_imported_at
    assert t1_import
    assert_equal 34, ICalendarEntry.where(imported_at: @ci.last_imported_at).count

    # calendars get updated over time. entries disappear; to keep track of this
    # we tag each entry with identifier that delineates when it was imported.
    # to simulate an ics changing over time, here we change the CI url

    @ci.update(url: @cal_url2)
    importer = CalendarImporter.new(@ci)
    importer.process!

    t2_import = @ci.reload.last_imported_at
    assert t2_import
    refute_equal t1_import, t2_import

    assert_equal 0, ICalendarEntry.where(imported_at: t1_import).count

    # t2 has 76 entries, and 20 of which recur, and 6 all days
    assert_equal 76, ICalendarEntry.where(calendar_import: @ci).count
    assert_equal 20, ICalendarEntry.where(calendar_import: @ci, recurs: true).count
    assert_equal 6, ICalendarEntry.where(calendar_import: @ci).
      where("start_date is not null and start_time is null").count
  end
end
