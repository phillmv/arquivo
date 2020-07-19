class CalendarImport < ApplicationRecord
  has_many :imported_calendar_entries, dependent: :delete_all

  def self.due_for_processing?
    where("last_imported_at < ?", 12.hours.ago).any?
  end
end
