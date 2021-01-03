require 'test_helper'

class EntryTest < ActiveSupport::TestCase
  setup do
    @notebook = Notebook.create(name: "test")
  end

  test "the identifier gets set" do
    entry = @notebook.entries.new(body: "body")
    refute entry.identifier

    assert entry.save

    assert entry.identifier =~ /\d\d\d\d\d\d\d\d/
  end

  test "#copy_parent" do
    parent_cal_entry = @notebook.entries.calendars.create(to: "foo@example.com, bar@example.com", from: "qux@example.com", body: "#test #right @foobar\n\nhello!\n\ntest")
    parent_note_entry = @notebook.entries.create(body: "#test #right @foobar\n\nhello!\n\ntest")

    new_entry = @notebook.entries.new

    new_entry.copy_parent(parent_note_entry)
    assert_equal "#test #right @foobar\n", new_entry.body

    new_entry.copy_parent(parent_cal_entry)
    assert_equal "#meeting @foo @bar", new_entry.body
  end

  test "yaml round trip works as you'd expect" do
    e = @notebook.entries.create(body: "whatever")
    assert_equal 1, Entry.count

    entry_attr = e.export_attributes
    assert entry_attr["identifier"]
    assert entry_attr["occurred_at"]
    assert entry_attr["created_at"]
    assert entry_attr["updated_at"]
    assert entry_attr["body"]

    Dir.mktmpdir do |dir|
      SyncToDisk.new(@notebook, dir).export!

      e.destroy
      assert_equal 0, Entry.count

      SyncFromDisk.new(@notebook.to_folder_path(dir)).import!

      assert_equal 1, Entry.count
      assert_equal entry_attr, Entry.last.export_attributes
    end
  end
end
