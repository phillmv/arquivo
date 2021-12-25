require 'test_helper'

class EntryLinkerTest < ActiveSupport::TestCase
  setup do
    @notebook = Notebook.create(name: "test")
    @linked_entry = @notebook.entries.notes.create(body: "# Hello world!\r\nI am a note!")
  end

  test "links are extracted" do
    assert_equal 0, Link.count
    body = <<~ENTRY_BODY
    #test

    https://example.com

    http://okayfail.com

    [[#{@linked_entry.identifier}]]

    @name

    <a href="https://example.com/example">another example</a>

    <a href="#foo">but this will not work</a>
    ENTRY_BODY
    entry = @notebook.entries.create(body: body)

    assert_equal 4, Link.count
    assert_equal 4, entry.links.count

    # this operation is idempotent
    EntryLinker.new(entry).link!

    assert_equal 4, Link.count
    assert_equal 4, entry.links.count

    # of note here is that the #test and @name links
    # are not included as "links", and neither is the anchor #foo
    expected_links = ["https://example.com",
                      "http://okayfail.com",
                      "/#{@notebook.owner}/#{@notebook}/#{@linked_entry.identifier}",
                      "https://example.com/example"]

    assert_equal entry.links.map(&:url).to_set, expected_links.to_set

    entry2 = @notebook.entries.create(body: "#foo #bar\r\nhttps://example.com")

    # since example.com has already been linked, the Link count does not increase
    assert_equal 4, Link.count
    assert_equal 5, LinkEntry.count
    assert_equal 1, entry2.links.count
  end
end
