class ScheduleEntryMaker
  attr_reader :notebook
  def initialize(notebook)
    @notebook = notebook
  end

  # my goal here is to go from a Schedule - a collection of events to entries.
  #
  # one way to do this is to have a backfill
  # that iterates from The Dawn Of Time
  #
  # and that's like… not the worst way to do it?
  # but years of working at WebScale have taught me to
  # Fear the unbounded query. i want dumb pipes
  # that do not require thinking to operate.
  #
  # so in the spirit of move forward and do the right
  # thing, what if… we fill in all of today's events
  # and check in on the past week?
  #
  # like, this will be a background job that runs.
  #
  # in a sense
  # i kind of want the Schedule to be a lazy collection
  # of event attributes
  # and i suspect i will have to do this renming
  # and resorting sooner than later
  #
  # anyways i will have to iterate over some kind
  # of time boundary, without necessarily doing
  # all of history every time
  # and once a week is sensible enough
  #
  # even just typing this out i feel the need to refactor it
  # i just Know this won't be a final solution
  # but i do want to get _something_ to work
  # only then will i know how to refactor


  # a good enough window
  def past_seven_days!
    notebook.calendar_imports.each do |calendar|
      events = Schedule.new(calendar).past_seven_days

      populate(notebook, events)
    end
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
    attributes.merge(kind: "calendar", identifier: event_to_identifier(event))
  end

  # do i want to use the sequence-id? the sequence-id denotes an _edit_
  # so if i include the sequence id i might get duplicates vs updates
  def event_to_identifier(event)
    # LOL
    # okay. if an event is an instance of a recurring event,
    # then it won't have a recurrence_id set, so we're back to where
    # we started at the begining of this insane ringamarole
    #
    # if i edit a recurring event in the future do i want it to be
    # retroactively updated here? probably not. assumption of this system
    # is an entry _already happened_. we might do a backfill once but
    # not on an ongoing basis eh? of what purpose is there to edit events
    # that have already occurred?
    #
    # if an event is edited it'll generate a recurrence_id or a sequence
    # if it's a recurring event it won't have that distinction: gotta
    # re-generate the list and diff it. fuck it let's go by occurred_at
    str = [event[:uid], event[:occurred_at]&.to_i].compact.join("-")
    # do I want to use sha256? vaguely concerned about collisions
    # but i feel like i should largely be safe? what about sha1?
    # it's technically unsafe for cryptographic use but 256 is SO LONG
    # gotta look up a url safe b64
    #
    # something to investigate: what if we used the occurred_at timestamp
    # PLUS some hexdigest bits? in the meantime let's just go ahead
    # with the hex digest
    Digest::SHA1.hexdigest(str)
  end
end
