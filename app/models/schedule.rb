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
    entries_for_this_calendar = ICalendarEntry.where(calendar_import: @calendar)

    non_recurring_entries = entries_for_this_calendar.where(recurs: false)
    normal_entries = non_recurring_entries.
      where("start_time >= ? and end_time <= ?", startt, endt)

    # all day entries have dates, not datetimes.
    # TODO: what if the end date is nil?
    all_day_normal_entries = non_recurring_entries.
      where(start_time: nil).
      where("start_date >= ? and end_date <= ?", startt, endt)

    normal_entries = normal_entries.or(all_day_normal_entries)

    all_events = normal_entries.map do |cal_entry|
      event_attributes(cal_entry)
    end


    # recurring events don't have finitely defined start and end
    # times, so we have to iterate over all of them regardless
    recurring = entries_for_this_calendar.where(recurs: true)

    recurring.each do |cal_entry|

      # occurrences_between outputs occurrence instances,
      # defined in the current *system* tz;
      #
      # normally, when doing datetime-aware comparisons, this is OK
      # but there's a TODO here for untangling what this would mean if we ever
      # support non-system time tz (i.e. all day events)

      cal_entry.occurrences_between(startt, endt).each do |inst|

        # all_day? events issue Date objects, not datetimes
        # so when this recurrence_id is saved to the database,
        # it is converted into UTC cos the column is a datetime
        #
        # since occurrences_between will coerce the Date into *system* tz,
        # the comparison for all_day? events will fail since midnight UTC and
        # midnight in <tz> are not the same *moment* in time.
        #
        # in order to make startt match up w/the recurrence_id, let's coerce
        # the recurrence_id to "midnight in UTC", by converting it back into
        # a date

        if cal_entry.all_day?
          query_recurrence_id = inst.start_time.to_date.to_datetime
        else
          query_recurrence_id = inst.start_time
        end

        recurrence_exceptions = normal_entries.where(uid: cal_entry.uid,
                                                     recurrence_id: query_recurrence_id)

        # if there's a normal cal_entry with the same uid and recurrence_id,
        # time to skip!
        if recurrence_exceptions.any?
          next
        else
          all_events << event_attributes(cal_entry, inst.start_time, inst.end_time)
        end
      end
    end

    all_events.sort_by { |h| h[:occurred_at] }
  end

  # TODO: move these fields into the cal entry?
  # add generation id timestamp for tracking deletions in CalEntry
  # need to hash uid, recurrence_id, sequence
  # icalendarentry should probably have notebook eh? why not
  
  # TODO: if an event is not recurring but also all day?
  # TODO: all day events have to be converted to User.tz on insertion

  # assumes we're getting an ICalendarEntry
  def event_attributes(event, start_time = nil, end_time = nil)
    {
      uid: event.uid,
      subject: event.summary.to_s.presence,
      from: event.organizer&.to&.presence,
      to: event.attendee.map(&:to).join(", ").presence,
      occurred_at: start_time || event.start_time || event.start_date,
      ended_at: end_time || event.end_time || event.end_date,
      state: event.status.to_s.presence,
      body: body(event),
      recurrence_id: event.recurrence_id,
      sequence: event.sequence,
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
