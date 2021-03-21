class User
  attr_accessor :name

  def self.name
    "phillmv"
  end

  def self.tz
    "Eastern Time (US & Canada)"
  end

  def self.current
    self.new(name: self.name)
  end

  def initialize(name:)
    @name = name
  end

  def notebooks
    Notebook.all
  end

  def to_param
    name
  end

  def to_s
    name
  end
end
