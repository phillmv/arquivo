class Setting < KeyValue
  # fyi, this gets overridden in test_helper
  DEFAULTS = {
    :arquivo => {
      storage_path: File.join(ENV["HOME"], "Documents")
    }
  }

  def self.default(namespace, key)
    if DEFAULTS[namespace][key]
      self.new(namespace: namespace,
               key: key,
               value: DEFAULTS[namespace][key])
    end
  end

  def self.get(namespace, key)
    v = super
    if v.nil?
      DEFAULTS[namespace][key]
    else
      v
    end
  end

  def self.fetch(namespace, key)
    kv = super
    if kv.nil?
      default(namespace, key)
    else
      kv
    end
  end
end
