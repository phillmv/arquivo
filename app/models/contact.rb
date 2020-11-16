class Contact < ApplicationRecord
  has_many :contact_entries
  has_many :entries, through: :contact_entries

  def see_ya!
    if entries.reload.empty?
      self.destroy
    end
  end
end
