class Contact < ApplicationRecord
  has_many :entries

  def see_ya!
    if entries.reload.empty?
      self.destroy
    end
  end
end
