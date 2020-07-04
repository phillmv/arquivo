# this class takes a calendar import, looks up its imported entries, and
# then "interprets" them to output event objects.
class Schedule
  attr_reader :calendar

  def initialize(calendar)
    @calendar = calendar
  end

  def today(tz = "UTC")
    Time.use_zone(tz) do
      startt = Date.today.beginning_of_day
      endt = startt.end_of_day
      events_for(startt, endt)
    end
  end

  def tomorrow(tz = "UTC")
    Time.use_zone(tz) do
      startt = Date.tomorrow.beginning_of_day
      endt = startt.end_of_day
      events_for(startt, endt)
    end
  end

  def this_week(tz = "UTC")
    Time.use_zone(tz) do
      if Date.current.sunday?
        monday = Date.tomorrow.beginning_of_day
      else
        monday = Date.current.monday.beginning_of_day
      end

      sunday = monday.sunday.end_of_day

      events_for(monday, sunday)
    end
  end

  def past_seven_days(tz = "UTC")
    Time.use_zone(tz) do
      startt = 7.days.ago.beginning_of_day
      endt = Date.today.end_of_day

      events_for(startt, endt)
    end
  end

  def events_for(startt, endt)
    # first, we fetch all the "normal", non recurring events
    entries_for_this_calendar = @calendar.imported_calendar_entries
    normal_entries = entries_for_this_calendar.
      where(recurs: false).
      where("start_time >= ? and end_time <= ?", startt, endt)

    # due to how we serialize dates, the query for all day events is different
    # all day entries have dates, not datetimes, so the _time cols should be nil
    all_day_normal_entries = entries_for_this_calendar.
      where(start_time: nil, recurs: false).
      where("start_date >= ? and end_date <= ?", startt, endt)

    normal_entries = normal_entries.or(all_day_normal_entries)

    all_events = normal_entries.map do |cal_entry|
      event_attributes(cal_entry)
    end


    # recurring events have recurring rulesets, as opposed to fixed start and
    # end times that we can query.
    #
    # therefore, we have to iterate over EVERY SINGLE RECURRING event entry
    recurring = entries_for_this_calendar.where(recurs: true)

    recurring.each do |cal_entry|
      # occurrences_between generates instances w/datetimes
      # set in the system timezone
      #
      # meanwhile, the icalendarentry recurrence_id is serialized
      # as a UTC datetime
      cal_entry.occurrences_between(startt, endt).each do |inst|
        # this trips us up in the case of all day events:
        #
        # inst.start_time will be beginning_of_day in system tz, while
        #   recurrence_id will be beginning_of_day in utc

        # for this reason, if dealing with a date object,
        # we convert it to beginning of day in utc
        if cal_entry.all_day?
          query_recurrence_id = inst.start_time.to_date.to_datetime
        else
          query_recurrence_id = inst.start_time
        end

        # with all of the above in mind, we use the recurrence_id to find out
        # whether there are any overlapping, edited, recurring events
        edited_recurrences = normal_entries.where(uid: cal_entry.uid,
                                                  recurrence_id: query_recurrence_id)

        # and if so, move on:
        if edited_recurrences.any?
          next
        else
          all_events << event_attributes(cal_entry, inst.start_time, inst.end_time)
        end
      end
    end

    all_events.sort_by { |h| h[:occurred_at] }
  end

  # keep in mind that occurred_at and ended_at will have to be converted
  # into the User timezone in the event they are dates.
  #
  # also, that we could be passing along the recurrence_id & sequence
  def event_attributes(event, start_time = nil, end_time = nil)
    {
      uid: event.uid.to_s,
      subject: event.summary.to_s.presence,
      from: event.organizer&.to&.presence,
      to: event.attendee.map(&:to).join(", "),
      occurred_at: start_time || event.start_time || event.start_date,
      ended_at: end_time || event.end_time || event.end_date,
      state: event.status.to_s,
      body: body(event),
      sequence: event.sequence.to_s,
      recurrence_id: event.recurrence_id
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
