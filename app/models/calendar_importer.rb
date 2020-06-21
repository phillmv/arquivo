require 'open-uri'
class CalendarImporter
  attr_accessor :calendars, :calendar_import

  def initialize(calendar_import)
    @calendar_import = calendar_import
    ical_file = open(@calendar_import.url).read

    # ical files can define multiple calendars in a single file
    @calendars = Icalendar::Calendar.parse(ical_file)
  end

  def events
    @events ||= @calendars.map(&:events).flatten
  end

  def map_attributes(ci, name, event, last_imported_at)
    attributes = {
      calendar_import_id: ci.id,
      name: name,
      uid: event.uid.to_s,
      recurrence_id: event.recurrence_id.to_s,
      sequence: event.sequence.to_s,
      recurs: event.rrule.any?,
      body: event.to_ical,
      last_imported_at: last_imported_at
    }

    # if the start time is a date, we treat it differently
    if event.dtstart.value.is_a?(Date)
      attributes = attributes.merge(start_date: event.dtstart.to_s,
                                    end_date: event.dtend.to_s,
                                    start_time: nil,
                                    end_time: nil)
    else
      attributes = attributes.merge(start_time: event.dtstart.to_s,
                                    end_time: event.dtend.to_s,
                                    start_date: nil,
                                    end_date: nil)
    end

    attributes
  end

  def process!
    # used as an identifier to weed out since-deleted entries
    last_imported_at = Time.current

    calendars.each do |cal|
      name = cal.custom_properties["x_wr_calname"]&.first || "noname"
      cal.events.each do |event|
        ImportedCalendarEntry.transaction do
          recurrence_id = event.recurrence_id

          # nil.to_s => ""
          # where(recurrence_id: "") => durr can't find anything
          # where(recurrence_id: nil) => oh you meant IS NULL, gotcha

          if !recurrence_id.nil?
            recurrence_id = recurrence_id.to_s
          end

          entry = ImportedCalendarEntry.find_by(calendar_import_id: calendar_import.id,
                                         uid: event.uid.to_s,
                                         recurrence_id: recurrence_id,
                                         sequence: event.sequence.to_s)

          entry_attributes = map_attributes(calendar_import, name, event, last_imported_at)

          if entry
            entry.update(entry_attributes)
          else
            ImportedCalendarEntry.create(entry_attributes)
          end
        end
      end
    end

    # TODO: make this all more atomic
    calendar_import.update(last_imported_at: last_imported_at)
    ImportedCalendarEntry.where(calendar_import_id: calendar_import.id).
      where("last_imported_at != ?", last_imported_at).delete_all
  end
end
