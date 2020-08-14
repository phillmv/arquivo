class KeyValue < ApplicationRecord
  def self.fetch(namespace, key)
    where(namespace: namespace, key: key).first
  end

  def self.get(namespace, key)
    fetch(namespace, key)&.value
  end

  def self.set(namespace, key, value)
    self.transaction do
      if kv = get(namespace, key)
        kv.update(value: value)
      else
        create(namespace: namespace, key: key, value: value)
      end
    end
  end
end
