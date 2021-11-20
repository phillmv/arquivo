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

  test "tags are also created from metadata" do
    assert_equal 0, @notebook.tags.count

    # the entry tagger will look up the tags key in the metadata
     entry = @notebook.entries.create(body: "#foo #bar #baz\r\nsome more text #anothertag", metadata: {tags: ["#faketag1", "#faketag2", "#foo"]})

     assert_equal 6, entry.tags.uniq.count

     # but "tags" will get precendence over :tags

     entry2 = @notebook.entries.create(body: "#foo", metadata: {"tags" => ["#mytag"], tags: ["#faketag1", "#faketag2", "#foo"]})

     assert_equal ["#foo", "#mytag"].to_set, entry2.tags.pluck(:name).to_set

     # also for shits and giggles we support a flat string
     # cos it might be annoying to type an array in the yaml frontmatter
     entry3 = @notebook.entries.create(body: "#foo", metadata: {"tags" => "#tag1, #tag2 , #tag3 tag4", tags: ["#meh"]})

     assert_equal ["#foo", "#tag1", "#tag2", "#tag3", "#tag4"].to_set, entry3.tags.pluck(:name).to_set
  end
end

