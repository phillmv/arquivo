require 'test_helper'

require File.join(Rails.root, "db/migrate/20220801211909_migrate_to_thread_identifier")

class MigrateToThreadIdentifierTest < ActiveSupport::TestCase
  test "the migration behaves correctly" do
    enable_local_sync do
      @notebook = Notebook.create(name: "mctesttest")
      e1 = @notebook.entries.create(body: "test 1")
      e2 = @notebook.entries.create(body: "test 2", in_reply_to: e1.identifier)
      e3 = @notebook.entries.create(body: "test 3", in_reply_to: e2.identifier)
      e31 = @notebook.entries.create(body: "test 3.1", in_reply_to: e2.identifier)
      e4 = @notebook.entries.create(body: "test 4", in_reply_to: e3.identifier)

      assert_nil e2.thread_identifier
      assert_equal e1.identifier, e2.in_reply_to

      assert_nil e3.thread_identifier
      assert_equal e2.identifier, e3.in_reply_to

      assert_nil e31.thread_identifier
      assert_equal e2.identifier, e31.in_reply_to

      assert_nil e4.thread_identifier
      assert_equal e3.identifier, e4.in_reply_to

      ENV["YES_REALLY_RUN_THIS"] = "true"
      MigrateToThreadIdentifier.migrate(:up)

      [e1, e2, e3, e31, e4].each(&:reload)

      assert_nil e1.thread_identifier

      assert_equal e1.identifier, e2.thread_identifier
      assert_equal e1.identifier, e2.in_reply_to

      assert_equal e1.identifier, e3.thread_identifier
      assert_equal e2.identifier, e3.in_reply_to

      assert_equal e1.identifier, e31.thread_identifier
      assert_equal e2.identifier, e31.in_reply_to

      assert_equal e1.identifier, e4.thread_identifier
      assert_equal e3.identifier, e4.in_reply_to
    end
  end
end

