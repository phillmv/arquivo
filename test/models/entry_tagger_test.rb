require 'test_helper'

class EntryTaggerTest < ActiveSupport::TestCase
  setup do
    @notebook = Notebook.create(name: "test")
  end

  test "when an entry is created, tags are also created" do
    assert_equal 0, @notebook.tags.count

    entry = @notebook.entries.create(body: "#foo #bar #baz\r\nsome more text #anothertag")

    assert_equal 4, @notebook.tags.count
    assert_equal 4, entry.tags.count

    # this operation is idempotent
    old_tags = entry.tags.map(&:name).to_set

    EntryTagger.new(entry).process!

    assert_equal old_tags, entry.reload.tags.map(&:name).to_set

    # and it works across entries

    entry2 = @notebook.entries.create(body: "#foo #bar\r\nmore gibberish #qux")

    # we've added the #qux tag
    assert_equal 5, @notebook.tags.count
    assert_equal 3, entry2.tags.count

    # when we remove a tag, & it's no longer referenced anywhere,
    # we delete the global tag row
    # let's get rid of #bar
    entry.update(body: "#foo #baz\r\nsome more text #anothertag")

    # since it's referenced in entry2, no decrement
    assert_equal 5, @notebook.tags.count
    assert_equal 3, entry.tags.count

    entry2.update(body: "#foo\r\nmore gibberish #qux")
    assert_equal 2, entry2.tags.count

    # #bar is no more
    assert_equal 4, @notebook.tags.count
  end
end

