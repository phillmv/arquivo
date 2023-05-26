=begin #commented out during rails 7 upgrade
PAUSE_JOBS = Concurrent::Atom.new(false)

if ::ActiveRecord::Base.connection_config[:adapter] == 'sqlite3'
  if c = ::ActiveRecord::Base.connection
    c.execute 'PRAGMA journal_mode = WAL;'
    # c.execute 'PRAGMA busy_timeout = 5000;'
  end

  # ActiveRecord::Base.connection.raw_connection.busy_handler do |count|
  #   if count * 100 > 50000
  #     false
  #   else
  #     sleep(100)
  #     true
  #   end
  # end

  # if defined?(ActiveRecord::ConnectionAdapters::SQLite3::DatabaseStatements)
  #   module ActiveRecord::ConnectionAdapters::SQLite3::DatabaseStatements
  #     def begin_db_transaction
  #       log("begin transaction", "TRANSACTION") { @connection.transaction(:immediate) }
  #     end
  #   end
  # else
  #   raise "No DatabaseStatements to override!"
  # end
end
=end
