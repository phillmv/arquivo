class Notebook < ApplicationRecord
  has_many :calendar_imports, foreign_key: :notebook, primary_key: :name
  has_many :entries, foreign_key: :notebook, primary_key: :name
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
