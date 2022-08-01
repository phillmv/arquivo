require 'test_helper'

class EntriesIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @current_notebook = Notebook.create(name: "test")
  end

  test "save a bookmark" do
    get save_bookmark_path(notebook: @current_notebook), params: { url: "http://example.com", subject: "foo" }
    assert_response :success

    assert_select('input[value="http://example.com"]')
    assert_select('input[value="foo"]')


    assert 0, Entry.count

    post create_or_update_entry_path(notebook: @current_notebook), params: { entry: { url: "http://example.com", subject: "foo", body: "lol" } }

    assert 1, Entry.count
    bookmark = Entry.last

    assert bookmark.bookmark?

    assert_equal Digest::MD5.hexdigest("http://example.com"), bookmark.identifier
    assert_equal "foo", bookmark.subject
    assert_equal "lol", bookmark.body

    # and if we post the same url twice, the fields get updated

    post create_or_update_entry_path(notebook: @current_notebook), params: { entry: { url: "http://example.com", subject: "a different subject", body: "#with #tags #now lol" } }

    assert 1, Entry.count

    bookmark.reload
    assert_equal Digest::MD5.hexdigest("http://example.com"), bookmark.identifier
    assert_equal "a different subject", bookmark.subject
    assert_equal "#with #tags #now lol", bookmark.body

    # hitting /save on an existing bookmark brings up its deets
    get save_bookmark_path(notebook: @current_notebook), params: { url: "http://example.com", subject: "foo" }

    assert_select('input[value="a different subject"]')
    # where did the \n come from in the textarea?, strip for now
    assert_equal "#with #tags #now lol", css_select('textarea').inner_text.strip

    # we currently don't do any normalization but maybe we should
    # here the url has an extra /
    post create_or_update_entry_path(notebook: @current_notebook), params: { entry: { url: "http://example.com/", subject: "a different subject", body: "#with #tags #now lol" } }

    assert 2, Entry.count
  end

  test "create a threaded entry" do
    entry1 = @current_notebook.entries.create(body: "test 1")
    post create_entry_path(owner: @current_notebook.owner, notebook: @current_notebook), params: { entry: { body: "test mc test", in_reply_to: entry1.identifier } }

    entry2 = Entry.last

    assert_equal entry1.identifier, entry2.in_reply_to
    assert_equal entry1.identifier, entry2.thread_identifier

    post create_entry_path(owner: @current_notebook.owner, notebook: @current_notebook), params: { entry: { body: "test mc test", in_reply_to: entry2.identifier } }

    entry3 = Entry.last
    assert_equal entry2.identifier, entry3.in_reply_to
    assert_equal entry1.identifier, entry3.thread_identifier


  end
end
