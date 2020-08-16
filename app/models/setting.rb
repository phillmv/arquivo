class Setting < KeyValue
  # fyi, this gets overridden in test_helper
  DEFAULTS = {
    :arquivo => {
      storage_path: File.join(ENV["HOME"], "Documents")
    }
  }

  def self.default(namespace, key)
    self.new(namespace: namespace,
             key: key,
             value: DEFAULTS[namespace][key])
  end

  def self.get(namespace, key)
    v = super
    if v.nil?
      DEFAULTS[namespace][key]
    else
      v
    end
  end
end
