require 'open-uri'
class CalendarHandler
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

  def map_attributes(name, event)
    {
      calendar_import_id: calendar_import.id,
      name: name,
      uid: event.uid.to_s,
      recurrence_id: event.recurrence_id.to_s,
      sequence: event.sequence.to_s,
      start_time: event.dtstart.to_s,
      end_time: event.dtend.to_s,
      recurs: event.rrule.any?,
      body: event.to_ical
    }
  end

  def process!
    calendars.each do |cal|
      name = cal.custom_properties["x_wr_calname"]&.first || "noname"
      cal.events.each do |event|
        ICalendarEntry.transaction do
          entry = ICalendarEntry.find_by(calendar_import_id: calendar_import.id,
                                         uid: event.uid.to_s,
                                         recurrence_id: event.recurrence_id.to_s,
                                         sequence: event.sequence.to_s)

          if entry
            entry.update(map_attributes(name, event))
          else
            ICalendarEntry.create(map_attributes(name, event))
          end
        end
      end

      # Entry.transaction do
      #   e = Entry.find_by(notebook: notebook, identifier: event.uid.to_s)
      #   if e
      #     e.update_attributes(map_attributes(event))
      #   else
      #     Entry.create(map_attributes(event))
      #   end
      # end
    end
  end

  def old_map_attributes(event)
    {
      notebook: notebook,
      identifier: event.uid.to_s,
      subject: event.summary.to_s.presence,
      from: event.organizer&.to&.presence,
      to: event.attendee.map(&:to).join(", "),
      occurred_at: event.dtstart.to_s,
      ended_at: event.dtend.to_s,
      state: event.status.to_s,
      body: body(event),
      kind: "calendar",
      source: cal_name(event)
    }
  end

  # let's do something dumb and easy first.
  # def body(event)
  #   [location(event),
  #    event.description].select(&:present?).join("\n\n")
  # end
  #
  # def location(event)
  #   if event.location.present?
  #     "Location: #{event.location}"
  #   else
  #     nil
  #   end
  # end
  #
  # # change later
  # def cal_name(event)
  #   event.parent.custom_properties["x_wr_calname"]
  # end
end
