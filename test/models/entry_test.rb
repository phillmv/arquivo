require 'test_helper'

class EntryTest < ActiveSupport::TestCase
  setup do
    @notebook = Notebook.create(name: "mctesttest")
    @file_path = File.join(Rails.root, "test", "fixtures", "test_image.jpg")
  end

  test "an identifier gets set by default, and it resembles a date with some random letters" do
    entry = @notebook.entries.new(body: "body")
    refute entry.identifier

    assert entry.save

    match = entry.identifier =~ /\d\d\d\d\d\d\d\d-[23456789cfghjmpqrvwx]{4}/

    # I've been suffering from some flaky tests, so let's try to get some debugging info
    if match.nil?
      puts "HELLO WHAT IS GOING ON with #{entry.identifier}"
    end
    assert match
  end

  # written 2023-05-20: is it truly possible that i began setting the subject
  # automatically in august of 2021 but never tested it until now?
  # really, a test of the SubjectExtractorFilter
  test "the subject is set automatically based on the first 3 lines of the entry's body" do
    # we only set a subject if the body has an h1 or an h2
    no_subject = @notebook.entries.create(body: "body")

    assert_nil no_subject.subject

    # has an h2 set
    h2_subject = @notebook.entries.create(body: "## my subject\nhi")

    assert_equal "my subject", h2_subject.subject

    # if more than one heading is set it picks the first one
    h2h1_subject = @notebook.entries.create(body: "## first line\n# second line\nhi")

    assert_equal "first line", h2h1_subject.subject

    # but only if its set in the first 3 lines, as defined by the markdown's output
    # (hence \n\n's)
    gasp_no_subject = @notebook.entries.create(body: "line1\n\nline2\b\nline3\n\n## this won't get read\n# neither will this\nhi")
    assert_nil gasp_no_subject.subject
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
    enable_local_sync do
      entry = @notebook.entries.create(body: "foo bar")
      blob = ActiveStorage::Blob.create_and_upload!(io: File.open(@file_path), filename: "image.jpg")
      blob.analyze
      entry.files.create(blob_id: blob.id, created_at: blob.created_at)

      assert 1, Entry.count

      target_notebook = Notebook.create(name: "test-target")
      assert 0, target_notebook.entries.count

      copy = entry.copy_to!(target_notebook)
      assert 1, target_notebook.entries.count

      puts "WHY IS THIS DIFF IS IT COS OF OCCURRED AT #{entry.occurred_at.to_f} | #{copy.occurred_at.to_f}"
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

      second_blob = ActiveStorage::Blob.create_and_upload!(io: File.open(@file_path), filename: "another_image.jpg")
      copy.files.create(blob_id: second_blob.id, created_at: second_blob.created_at)

      # let's reload the object wholesale
      copy = Entry.find(copy.id)
      assert_equal 2, copy.files.blobs.count
      refute_equal entry.files.blobs.pluck(:filename, :checksum).to_set, copy.files.blobs.pluck(:filename, :checksum).to_set

      # now we copy again and assert that it's identical
      copy = entry.copy_to!(target_notebook)

      assert_equal entry.attributes.except("id", "notebook", "created_at" ,"updated_at"), copy.attributes.except("id", "notebook", "created_at", "updated_at")
      # and the other file is now gone, there is only 1 attachment
      assert_equal 1, copy.files.blobs.count

      assert_equal entry.files.blobs.pluck(:filename, :checksum).to_set, copy.files.blobs.pluck(:filename, :checksum).to_set
    end
  end

  test "an entry can be deleted" do
    entry = @notebook.entries.create(body: "a different entry http://example.com #foobar @namehere\n\n- [ ] a task")

    entry.files.attach(io: File.open(@file_path), filename: 'image.jpg')

    assert_equal 1, Entry.count

    assert entry.destroy
    assert_equal 0, Entry.count
  end

  test "metadata is a hash" do
    e = @notebook.entries.new
    assert_equal Hash.new, e.metadata

    e.save!

    assert_equal 1, @notebook.entries.count
    e = @notebook.entries.last
    assert_equal Hash.new, e.metadata

    # random keys can be set, no problemo
    e.metadata[:foo] = "blah"
    e.metadata["foo"] = "meh"
    e.metadata[:integer] = 1234
    e.metadata[:date] = "1989-11-09".to_date
    e.save!
    e = @notebook.entries.last

    assert_equal e.metadata[:foo], "blah"
    assert_equal e.metadata["foo"], "meh"
    assert_equal e.metadata[:integer], 1234
    assert_equal e.metadata[:date], "1989-11-09".to_date
  end

  test "basic threading" do
    e1 = @notebook.entries.create(body: "test 1")
    e2 = @notebook.entries.create(body: "test 2", in_reply_to: e1.identifier)
    e3 = @notebook.entries.create(body: "test 3", in_reply_to: e2.identifier)
    e31 = @notebook.entries.create(body: "test 3.1", in_reply_to: e2.identifier)
    e4 = @notebook.entries.create(body: "test 4", in_reply_to: e3.identifier)

    assert_equal e31.thread_ancestors.to_set, [e1, e2, e3].to_set
    assert_equal e4.thread_ancestors.to_set, [e1, e2, e3, e31].to_set

    assert_equal e2.thread_descendants.to_set, [e3, e31, e4].to_set
    assert_equal e3.thread_descendants.to_set, [e31, e4].to_set
    assert_equal e4.thread_descendants.to_set, [].to_set
  end
end
