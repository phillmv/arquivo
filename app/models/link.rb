class Link < ApplicationRecord
  has_many :link_entries
  has_many :entries, through: :link_entries

  before_create :set_identifier

  def set_identifier
    self.identifier = Digest::MD5.hexdigest(self.url)
  end
end
