# a little maker for encapsulating entry creation behaviour.
# orig. created to handle setting identifiers from subjects, but there's no
# reason why in the near future this shouldn't handle _all_ of the entry callbacks
# i.e. - set_identifier, set_subject, set_thread_identifier
# but also even like, syncing to git and processing tags, contacts, links, etc.
class EntryMaker
  def initialize(current_notebook)
    @current_notebook = current_notebook
  end

  def create(entry_params)
    @entry = nil
    err = true
    Entry.transaction do
      @entry = @current_notebook.entries.find_by(identifier: entry_params[:identifier])
      @entry ||= @current_notebook.entries.new(entry_params)

      # TODO: rename on update, but only if no other articles link to it yet.
      if @entry.generated_identifier?
        if @entry.set_subject.present?
          @entry.identifier = @entry.subject.parameterize
        end

        # TODO: need to restrict this up to 100 times or w/e
        while @current_notebook.entries.find_by(identifier: @entry.identifier)
          dash_number = @entry.identifier.match(/-\d+$/).to_s

          if dash_number.blank?
            @entry.identifier = "#{@entry.identifier}-1"
          else
            new_number = dash_number.gsub("-", "").to_i + 1
            @entry.identifier = @entry.identifier.gsub(dash_number, "-#{new_number}")

          end
        end
      end

      if @entry.new_record?
        err = !@entry.save
      else
        err = !@entry.update(entry_params)
      end
    end

    return [@entry, err]
  end
end
