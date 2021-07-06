require 'test_helper'

class StaticImportExportTest < ActionDispatch::IntegrationTest
  # i should be testing the rake task directly?
  # and i should be able to:
  # - test this without the test suite being run in "static mode"
  # - test the wget interaction from within rails test, vs starting
  # a separate test command (ie booting up the server first)
  # BUT one step at a time.
  #
  # First let's build some guarantees that the SyncerFromDisk
  # does the right thing:

  test "static import reads in non-standard notebooks & figures out what to do with it" do
    if !Arquivo.static?
      puts "Not in static mode. Try again, with STATIC_PLS=true"
      return
    end

    # let's establish that the system is empty
    assert_equal 0, Notebook.count
    assert_equal 0, Entry.count

    notebook_path = File.join(Rails.root, "test/fixtures/test_static_site")
    SyncFromDisk.new(notebook_path).import!

    assert_equal 1, Notebook.count
    notebook = Notebook.last
    assert_equal "test_static_site", notebook.name
    assert_equal 4, notebook.entries.count
    assert_equal 2, notebook.entries.documents.count
    assert_equal 2, notebook.entries.notes.count

    # okay so a count of 2 documents is wrong:
    # we want the about.html to be processed as an entry methinks,
    # not a plain ol' document

    get "/"
    assert_response 200, "if this fails, ensure that the spring preloader isn't stuck loading tests in non-static mode"

    # by the default we get the following links for free:
    # (todo: test notebooks where entries don't define any tags or contacts)
    get "/tags"
    assert_response 200

    get "/contacts"
    assert_response 200

    get "/hidden_entries"
    assert_response 200

    # try getting individual pages:
    # get /about.html
    # get /2021/new_blog.html
    # want to test certain extensions (md & markdown),
    # want to test the folder paths
    # want to test the dates being set properly in the entries
    # want to test hidden field, and that hidden entries do not show up in the timeline

    # in the future, we can do:
    # get /feed.atom
    # get /calendar or /archive

    # and then we can start doing fancy shit like,
    # overriding layouts and custom stylesheets


    # okay so i've already discovered i want to test at least 3 versions of
    # static site generation:
    # 1. all the proper importing, markdown or not, entry paths etc
    # 2. a very basic site with no tags or contacts
    # 3. same as 1 or 2 but overriding the templates
  end
end
