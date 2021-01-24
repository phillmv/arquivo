require 'test_helper'

class EntryTest < ActiveSupport::TestCase
  setup do
    @notebook = Notebook.create(name: "test")
    @file_path = File.join(Rails.root, "test", "fixtures", "test_image.jpg")
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

  test "can copy between two notebooks" do
    entry = @notebook.entries.create(body: "foo bar")
    entry.files.attach(io: File.open(@file_path), filename: 'image.jpg')

    assert 1, Entry.count

    target_notebook = Notebook.create(name: "test-target")
    assert 0, target_notebook.entries.count

    copy = entry.copy_to(target_notebook)
    assert 1, target_notebook.entries.count

    assert_equal entry.attributes.except("id", "notebook", "created_at" ,"updated_at"), copy.attributes.except("id", "notebook", "created_at", "updated_at")

    # not literally the same blobs
    refute_equal entry.files.blobs, copy.files.blobs
    assert_equal entry.files.blobs.pluck(:filename, :checksum).to_set, copy.files.blobs.pluck(:filename, :checksum).to_set

    # wow ok so we have a copy that's pretty cool
    # all the auto inserted attachment urls will be broken but
    # that's separate problem. (maybe could be fixed eh?)
    #
    # but what happens when we copy the same entry twice?
    # i think… i want it to override any local changes. it'd be impossible
    # to adequately merge them together. and this way i have a mechanism
    # for keeping things consistent, i think.
    # so, if we re-copy the entry again it'll overwrite any changes we had
    # going on. in the future maybe we could issue a warning but for now
    # caveat emptor and trust in the edit history system (TODO: test?)

    # let's take the copy and 1) change its content and 2) upload another file
    copy.body = "some changes"
    copy.save!

    refute_equal entry.body, copy.body

    copy.files.attach(io: File.open(@file_path), filename: "another_image.jpg")
    assert_equal 2, copy.files.blobs.count
    refute_equal entry.files.blobs.pluck(:filename, :checksum).to_set, copy.files.blobs.pluck(:filename, :checksum).to_set

    # now we copy again and assert that it's identical
    copy = entry.copy_to(target_notebook)

    assert_equal entry.attributes.except("id", "notebook", "created_at" ,"updated_at"), copy.attributes.except("id", "notebook", "created_at", "updated_at")
    assert_equal 1, copy.files.blobs.count

    assert_equal entry.files.blobs.pluck(:filename, :checksum).to_set, copy.files.blobs.pluck(:filename, :checksum).to_set
  end

end
