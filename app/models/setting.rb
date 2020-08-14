class Setting < KeyValue
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
    kv = super
    if kv.nil?
      default(namespace, key)
    else
      kv
    end
  end
end
