class ICalendarEntry < ApplicationRecord
  belongs_to :calendar_import

  delegate :summary, :organizer, :attendee, :status, :location, :description, to: :event

  def event
    return @event if defined?(@event)

    @event = Icalendar::Event.parse(body).first
  end

  def occurrences_between(startt, endt)
    event.occurrences_between(startt, endt)
  end
end
