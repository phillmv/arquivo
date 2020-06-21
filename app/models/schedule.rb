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

  def past_seven_days
    in_our_timezone do
      startt = 7.days.ago.beginning_of_day
      endt = Date.today.end_of_day

      events_for(startt, endt)
    end
  end

  def events_for(startt, endt)
    entries_for_this_calendar = ICalendarEntry.where(calendar_import: @calendar)
    normal_entries = entries_for_this_calendar.
      where(recurs: false).
      where("start_time >= ? and end_time <= ?", startt, endt)

    # all day entries have dates, not datetimes.
    # we eliminate recurring events because we have to calculate recurrences regardless
    all_day_normal_entries = entries_for_this_calendar.
      where(start_time: nil, recurs: false).
      where("start_date >= ? and end_date <= ?", startt, endt)

    normal_entries = normal_entries.or(all_day_normal_entries)

    all_events = normal_entries.map do |cal_entry|
      event_attributes(cal_entry)
    end


    # OH i have to go over EVERY RECURRING not just the ones in this
    # time span

    recurring = entries_for_this_calendar.where(recurs: true)

    recurring.each do |cal_entry|
      # occurrences between is creating instances in the current timezone
      # the icalendarentry recurrence_id is being serialized as a UTC datetime
      # while the inst.start_time is in <current timezone>. 
      cal_entry.occurrences_between(startt, endt).each do |inst|
        # this fails in the case of all day events. inst.start_time will be
        # beginning_of_day in current tz; recurrence_id will be beginning_of_day in utc
      
        if cal_entry.all_day?
          # converts to beginning of day in utc, as opposed to system time jfc
          query_recurrence_id = inst.start_time.to_date.to_datetime
        else
          query_recurrence_id = inst.start_time
        end

        edited_recurrences = normal_entries.where(uid: cal_entry.uid,
                                                  recurrence_id: query_recurrence_id)

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
  # specifically what's going on is that if an event is all day
  # it is stored as a Date, not a DateTime, but that gets converted
  # into "start of day in UTC" which is why it's showing up at 8pm
  # EST, which is not what i want.
  # i suspect this might mess up boundaries? like,
  # give me all the events between this date and that date.
  # TODO: if an event is not recurring but also all day
  # TODO: all day events have to be converted to EST on insertion
  #
  #
  # SEVERAL ISSUES HERE,
  # 1. recurrence_id is sometimes a Date, which will get stored as a DateTime in UTC
  # 2. occurrences_between will generate datetimes in _system_ time, irrespective
  # of Time.zone (which is a rails thing)
  #
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
