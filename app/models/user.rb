class User
  attr_accessor :name

  if Arquivo.static?
    def self.name
      "owner"
    end
  else
    def self.name
      "phillmv"
    end
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
