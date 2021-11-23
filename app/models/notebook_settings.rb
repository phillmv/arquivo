# honestly, just a quick convenience wrapper
class NotebookSettings
  attr_reader :notebook_namespace
  FORCE_BOOL = {
    "disable_mentions" => true
  }
  def initialize(notebook)
    @notebook_namespace = "notebook-#{notebook}"
  end

  def get(key)
    v = Setting.get(notebook_namespace, key) || Setting::DEFAULTS.dig(:site, key)

    if FORCE_BOOL[key]
      case v
      when nil
        false
      when "f"
        false
      when "t"
        true
      end
    else
      v
    end
  end

  def set(key, value)
    Setting.set(notebook_namespace, key, value)
  end

  def all
    Setting.where(namespace: notebook_namespace)
  end

  def render_options
    self.all.where(key: ["sanitize", "smart_punctuation"]).map do |s|

      value = case s.value
              when "f"
                false
              when "t"
                true
              else
                s.value
              end

      [s.key.to_sym,value]
    end.to_h
  end

  def disable_mentions?
    get("disable_mentions")
  end
end
