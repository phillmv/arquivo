class Notebook < ApplicationRecord
  has_many :calendar_imports, foreign_key: :notebook, primary_key: :name
  has_many :entries, foreign_key: :notebook, primary_key: :name
  has_many :links, foreign_key: :notebook, primary_key: :name
  has_many :tags, foreign_key: :notebook, primary_key: :name
  has_many :saved_searches, foreign_key: :notebook, primary_key: :name

  def self.for(name)
    self.find_by(name: name)
  end

  def self.default
    "journal"
  end

  def to_s
    name
  end

  def to_param
    name
  end

  def filesystem_path(path = nil)
    path ||= Setting.get(:arquivo, :arquivo_path)
    File.join(path, self.to_s)
  end
end
