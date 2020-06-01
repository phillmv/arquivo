class Schedule
  attr_reader :calendar

  def initialize(calendar)
    @calendar = calendar
  end

  def in_our_timezone(&block)
    Time.use_zone(User.tz, &block)
  end

  def today
    in_our_timezone do
      startt = Date.today.beginning_of_day
      endt = startt.end_of_day
      events_for(startt, endt)
    end
  end

  def tomorrow
    in_our_timezone do
      startt = Date.tomorrow.beginning_of_day
      endt = startt.end_of_day
      events_for(startt, endt)
    end
  end

  def this_week
    in_our_timezone do
      if Date.current.sunday?
        monday = Date.tomorrow.beginning_of_day
      else
        monday = Date.current.monday.beginning_of_day
      end

      sunday = monday.sunday.end_of_day

      events_for(monday, sunday)
    end
  end

  def events_for(startt, endt)
    normal_entries = ICalendarEntry.where(calendar_import: @calendar).where("start_time >= ? and end_time <= ?", startt, endt)

    normal_entries = normal_entries.where(recurs: false)

    recurring =  ICalendarEntry.where(calendar_import: @calendar).where(recurs: true)

    all_events = normal_entries.map do |cal_entry|
      event_attributes(cal_entry)
    end

    # OH i have to go over EVERY RECURRING not just the ones in this
    # time span

    recurring.each do |cal_entry|
      cal_entry.occurrences_between(startt, endt).each do |inst|
        edited_recurrences = normal_entries.where(uid: cal_entry.uid,
                                                  recurrence_id: inst.start_time)

        # if there's a cal_entry with the same uid and recurrence_id,
        # time to skip!
        if edited_recurrences.any?
          next
        else
          all_events << event_attributes(cal_entry, inst.start_time, inst.end_time)
        end
      end
    end

    all_events.sort_by { |h| h[:occurred_at] }
  end

  # todo: move these fields into the cal entry
  # make the var names more coherent
  # add generation id timestamp for tracking deletions
  # need to hash uid, recurrence_id, sequence
  # icalendarentry should probably have notebook eh? why not
  # # need to add all day to handle tz properly / implement all_day?
  def event_attributes(event, start_time = nil, end_time = nil)
    {
      identifier: event.uid.to_s,
      subject: event.summary.to_s.presence,
      from: event.organizer&.to&.presence,
      to: event.attendee.map(&:to).join(", "),
      occurred_at: start_time || event.start_time,
      ended_at: end_time || event.end_time,
      state: event.status.to_s,
      body: body(event),
      kind: "calendar",
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
end
