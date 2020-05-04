require 'open-uri'
class CalendarHandler
  attr_accessor :url, :notebook
  def initialize(notebook, url)
    @notebook = notebook
    @url = url

    ical_file = open(url).read
    @calendars = Icalendar::Calendar.parse(ical_file)
  end

  def events
    @events ||= @calendars.map(&:events).flatten
  end

  def process!
    events.each do |event|
      Entry.transaction do
        e = Entry.find_by(notebook: notebook, identifier: event.uid.to_s)
        if e
          e.update_attributes(map_attributes(event))
        else
          Entry.create(map_attributes(event))
        end
      end
    end
  end

  # TODO missing organizer!
  def map_attributes(event)
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
  def body(event)
    [location(event),
     event.description].select(&:present?).join("\n\n")
  end

  def location(event)
    if event.location.present?
      "Location: #{event.location}"
    else
      nil
    end
  end

  # change later
  def cal_name(event)
    event.parent.custom_properties["x_wr_calname"]
  end
end
