class ScheduleEntryMaker
  attr_reader :notebook
  def initialize(notebook)
    @notebook = notebook
  end

  # TODO:
  # - figure out how to backfill
  # - refactor?
  # - test this class, i.e. the tz shift

  # a good enough window
  def past_seven_days!
    notebook.calendar_imports.each do |calendar|
      events = Schedule.new(calendar).past_seven_days

      populate(notebook, events)
    end
  end

  def in_our_timezone(&block)
    Time.use_zone(User.tz, &block)
  end

  def populate(notebook, events)
    events.each do |event|
      entry_attributes = event_to_entry(event)

      Entry.transaction do
        entry = Entry.for_notebook(notebook).find_by(identifier: entry_attributes[:identifier])

        if entry
          entry.update(entry_attributes)
        else
          Entry.for_notebook(notebook).create(entry_attributes)
        end
      end
    end
  end

  def event_to_entry(event)
    attributes = event.except(:uid, :recurrence_id, :sequence)
    attributes[:metadata] = event.slice(:uid, :recurrence_id, :sequence).to_yaml

    # convert all day events to the current timezone
    # arguably, this calc could be happening at the Schedule level
    # but it feels like the insertion point is the right place to handle it
    if attributes[:occurred_at].is_a?(Date)
      in_our_timezone do
        attributes[:occurred_at] = attributes[:occurred_at].beginning_of_day
      end
    end

    if attributes[:ended_at].is_a?(Date)
      in_our_timezone do
        attributes[:ended_at] = (attributes[:ended_at] - 1.day).end_of_day
      end
    end

    attributes.merge(kind: "calendar", identifier: event_to_identifier(event))
  end

  # Calendar Events are uniquely identifiably by {uid, recurrence_id, sequence}
  # in our case, the recurrence_id is also the ocurred_at field, and that
  # if we did care to upsert events we probably want to ignore the sequence.
  #
  # consequently, we create an identifier using occurred_at and uid;
  # when we create Entrys the assumption is that it is a _past_ event, so edits
  # are not something to think about too much.
  def event_to_identifier(event)
    Entry.generate_identifier(event[:occurred_at], event[:uid])
  end
end
