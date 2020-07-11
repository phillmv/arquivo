require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Arquivo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    # config.assets.paths << Rails.root.join('node_modules')
    #
    if hostname = ENV.fetch("HOSTNAME", nil)
      config.hosts << hostname
    end
    config.hosts << "arquivo.localhost"

    # simple_calendar config
    config.beginning_of_week = :sunday
  end
end
