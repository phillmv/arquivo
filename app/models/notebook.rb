class Notebook < ApplicationRecord
  def self.default
    "journal"
  end

  def to_s
    name
  end

  def to_param
    name
  end
end
