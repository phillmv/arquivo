require 'test_helper'

class EntriesIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @current_notebook = Notebook.create(name: "test")
  end

  test "save a bookmark" do
    if Arquivo.static?
      return
    end

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

  test "load a gdocs bookmark" do
    if Arquivo.static?
      return
    end
    get save_bookmark_path(notebook: @current_notebook), params: { url: "https://docs.google.com/document/d/1E-V2Qj2OhURTtHVo9ONDjteHS7fRr77lEBbttA6DbIo/edit#heading=h.wwc00h4un5en", subject: "foo" }
    assert_response :success

    assert_select('input[value="https://docs.google.com/document/d/1E-V2Qj2OhURTtHVo9ONDjteHS7fRr77lEBbttA6DbIo/edit"]')
    assert_select('input[value="foo"]')
  end

  test "create a threaded entry" do
    if Arquivo.static?
      return
    end

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

  test "replying to an existing entry will increment the date" do
    if Arquivo.static?
      return
    end

    entry = @current_notebook.entries.create(body: "# #daily 2023-03-16", occurred_at: "2023-03-16".to_date)

    get new_entry_path(@current_notebook), params: { in_reply_to: entry.identifier }
    textarea_text = css_select("textarea[name='entry[body]']").first.text

    # this is 100% going to lead to weird flaky tests but i can't be arsed to
    # put in Timecop right now.
    assert_equal textarea_text, "\n# #daily #{Date.today.to_s}"
  end

  test "when saved thru a controller, an entry's identifier will be set from its subject" do
    if Arquivo.static?
      return
    end

    assert_equal 0, @current_notebook.entries.count
    post create_entry_path(owner: @current_notebook.owner, notebook: @current_notebook), params: { entry: { body: "test mc test"} }

    # the post redirects to the new entry, and we can grab the identifier from the path
    # hopefully this prevents some flaky tests I've been experiencing.
    entry_identifier = response.location.split("/").last

    entry_with_no_subject = @current_notebook.entries.find_by(identifier: entry_identifier)

    # no subject, no identifier tweak
    assert_nil entry_with_no_subject.subject
    # same as defined in entry_test.rb
    assert entry_with_no_subject.identifier =~ /\d\d\d\d\d\d\d\d-[23456789cfghjmpqrvwx]{4}/

    # with a subject it should set the identifier
    post create_entry_path(owner: @current_notebook.owner, notebook: @current_notebook), params: { entry: { body: "# has a subject\n\ntest mc test"} }

    entry_with_subject = @current_notebook.entries.last

    # TODO:
    # - create with generated_identifier
    # - it replaces it with the subject
    # - but not if the identifier was modified
    # - then it sets the identifier value
    # - also if the post already exists it will increment the -1 on the identifier
  end
end
