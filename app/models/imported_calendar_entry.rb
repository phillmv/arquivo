class ImportedCalendarEntry < ApplicationRecord
  self.table_name = "i_calendar_entries"
  belongs_to :calendar_import

  delegate :summary, :organizer, :attendee, :status, :location, :description, to: :event

  def event
    return @event if defined?(@event)

    @event = Icalendar::Event.parse(body).first
  end

  def occurrences_between(startt, endt)
    event.occurrences_between(startt, endt)
  end

  def all_day?
    event.dtstart.value.is_a?(Date)
  end
end
