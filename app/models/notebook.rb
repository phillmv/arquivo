class Notebook < ApplicationRecord
  def to_s
    name
  end

  def to_param
    name
  end
end
