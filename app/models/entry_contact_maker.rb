class EntryContactMaker
  UsernamePattern = HTML::Pipeline::MentionFilter::MentionPatterns[/[a-z0-9][a-z0-9-]*/]
  attr_reader :entry
  def initialize(entry)
    @entry = entry
  end

  def extract_contacts
    entry.body&.scan(UsernamePattern)&.flatten || []
  end

  def make!
    contact_list = extract_contacts.map do |name|
      contact = Contact.find_by(notebook: entry.notebook,
                                name: name)

      if contact
        if contact.updated_at < entry.updated_at
          contact.update(updated_at: entry.updated_at)
        end
      else
        contact = Contact.create(notebook: entry.notebook,
                                 name: name,
                                 updated_at: entry.updated_at)
      end

      contact
    end

    old_contacts = entry.contacts - contact_list

    entry.contacts = contact_list

    old_contacts.each(&:see_ya!)

    contact_list
  end
end
