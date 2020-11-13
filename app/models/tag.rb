class Tag < ApplicationRecord
  has_many :tag_entries
  has_many :entries, -> { distinct }, through: :tag_entries
  def to_s
    name
  end

  def to_param
    name
  end

  def apoptosis!
    if entries.reload.empty?
      self.destroy
    end
  end
end
