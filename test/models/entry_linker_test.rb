require 'test_helper'

class EntryLinkerTest < ActiveSupport::TestCase
  setup do
    @notebook = Notebook.create(name: "test")
  end

  test "links are extracted" do
    assert_equal 0, Link.count
    entry = @notebook.entries.create(body: "#test\n https://example.com\r\n\r\nhttp://okayfail.com")

    assert_equal 2, Link.count
    assert_equal 2, entry.links.count

    # this operation is idempotent
    EntryLinker.new(entry).link!

    assert_equal 2, Link.count
    assert_equal 2, entry.links.count

    assert_equal entry.links.map(&:url).to_set, ["https://example.com", "http://okayfail.com"].to_set

    entry2 = @notebook.entries.create(body: "#foo #bar\r\nhttps://example.com")

    assert_equal 2, Link.count
    assert_equal 1, entry2.links.count
  end
end
