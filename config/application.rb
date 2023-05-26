require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Arquivo
  PERMITTED_YAML = [Symbol, Date, Time, ActiveSupport::HashWithIndifferentAccess, ActiveSupport::TimeWithZone]
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.

    config.active_record.yaml_column_permitted_classes = PERMITTED_YAML

    if hostname = ENV.fetch("HOSTNAME", nil)
      config.hosts << hostname
    end
    config.hosts << "arquivo.localhost"

    # simple_calendar config
    config.beginning_of_week = :sunday

    # skip SyncToDisk, SyncWithGit in tests
    config.skip_local_sync = false

    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end

  def self.logger
    @logger ||= Logger.new(File.join(Rails.root, "log", "arquivo.log"))
  end

  def self.static?
    ENV["STATIC_PLS"]
  end
end

module Rails::ConsoleMethods
  def dat(str)
    notebook, identifier = str.split("/")

    if identifier.nil?
      Notebook.find_by(name: notebook)
    else
      Entry.find_by(notebook: notebook, identifier: identifier)
    end
  end
end
