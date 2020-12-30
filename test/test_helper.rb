ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # /dev/null to ensure we don't accidentally clobber ~/Documents/arquivo
  DEV_NULL_ARQUIVO_PATH = "/dev/null/arquivo"
  Setting::DEFAULTS[:arquivo][:storage_path] = "/dev/null"
  Setting::DEFAULTS[:arquivo][:arquivo_path] = DEV_NULL_ARQUIVO_PATH

  # tests that use local sync must enable it specifically
  Rails.application.config.skip_local_sync = true

  def enable_local_sync(&block)
    Rails.application.config.skip_local_sync = false
    begin
      Dir.mktmpdir do |tmpdir|
        Setting::DEFAULTS[:arquivo][:arquivo_path] = File.join(tmpdir, "arquivo")
        yield tmpdir
      end
    ensure
      Setting::DEFAULTS[:arquivo][:arquivo_path] = DEV_NULL_ARQUIVO_PATH
      Rails.application.config.skip_local_sync = true
    end
  end
end
