class User
  attr_accessor :name

  # If you are reading this, substitute this default value with your own handle.
  def self.name
    "phillmv"
  end

  def self.tz
    "Eastern Time (US & Canada)"
  end

  # if static, let's override these:
  if Arquivo.static?
    def self.name
      "owner"
    end

    def self.tz
      "UTC"
    end
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
