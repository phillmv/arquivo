class FeatureFlag < ApplicationRecord
  def self.[](name)
    find_by(name: name)&.active
  end

  def self.activate(name)
    if fflag = self.find_by(name: name)
      fflag.update(active: true)
    else
      fflag = self.create(name: name, active: true)
    end
  end

  def self.deactivate(name)
    if fflag = self.find_by(name: name)
      fflag.update(active: false)
    end
  end
end
