require 'test_helper'

class StaticSiteImportExportTest < ActionDispatch::IntegrationTest
  # i should be testing the rake task directly?
  # and i should be able to:
  # - test this without the test suite being run in "static mode"
  # - test the wget interaction from within rails test, vs starting
  # a separate test command (ie booting up the server first)
  # BUT one step at a time.
  #
  # First let's build some guarantees that the SyncerFromDisk
  # does the right thing:

  test "we can import non-standard notebook paths, make some clever inferences wrt content, and generate a default site using the simple_site fixture" do
    if !Arquivo.static?
      puts "Not in static mode. Try again, with STATIC_PLS=true"
      return
    end

    # let's establish that the system is empty
    assert_equal 0, Notebook.count
    assert_equal 0, Entry.count

    # and then we load in the simple_site content:
    notebook_path = File.join(Rails.root, "test/fixtures/static_sites/simple_site")
    SyncFromDisk.new(notebook_path).import!

    assert_equal 1, Notebook.count
    notebook = Notebook.last
    assert_equal "simple_site", notebook.name
    assert_equal 6, notebook.entries.count

    assert_equal 1, notebook.entries.documents.count
    assert_equal 5, notebook.entries.notes.count

    # All imported files in the notebook_path that do NOT have .html or
    # .(md|markdown) extensions get imported as document type entries.
    # To wit:

    notebook.entries.documents.find_by!(identifier: "youvechanged.jpg")

    # Some of these entries have special properties we want to verify.
    # Let us verify some attributes from:
    # - about.html
    # - 2021-07-06-convention-over-configuration
    # - musings.html
    # - yet-another-static-site
    # - 2021/should-just-work.html

    about_html = notebook.entries.notes.find_by!(identifier: "about.html")
    # even tho it is an html file, we can set metadata attributes thru its
    # frontmatter yaml, in this case the hide attribute.
    # aso, the contents of the file get stuffed into the body attribute
    assert about_html.hide
    assert_equal 0, about_html.body.index("<h1>Sample About Page")

    # we lop off .markdown extensions, we should have a 2021-07-06-convention-over-configuration
    # and its occurred at was defined in the filename.
    convention_over_conf = notebook.entries.notes.find_by!(identifier: "2021-07-06-convention-over-configuration")
    assert_equal DateTime.parse("Tue, 06 Jul 2021 00:00:00 UTC +00:00"), convention_over_conf.occurred_at

    # we lop off .markdown extensions, so we should have a musings.html
    musings = notebook.entries.notes.find_by!(identifier: "musings.html")

    # we lop off .md extensions, so we should have a yet-another-static-site
    # also, the date was defined in its front matter
    yass = notebook.entries.notes.find_by!(identifier: "yet-another-static-site")
    assert_equal DateTime.parse("2021-07-08"), yass.occurred_at

    # finally, the full folder path name becomes the identifier, so we should
    # also have a 2021/should-just-work.html
    should_just_work = notebook.entries.notes.find_by!(identifier: "2021/should-just-work.html")

    # ---
    # marvelous! let's go and test the properties of the default site that
    # gets generated with this content.
    # ---

    get "/"
    assert_response 200, "if this fails, ensure that the spring preloader isn't stuck loading tests in non-static mode"
    # TODO: ideally, test that pagination triggers, works, etc

    # by default we get the following links for free:
    # /tags, /contacts, /hidden_entries
    get "/tags"
    assert_response 200

    get "/contacts"
    assert_response 200

    # the simple_site fixture intentionally does not define @mentions or #tags
    # TODO: test that /tags and /contacts are empty?

    # we also get /hidden_entries to process entries with hide: true, ie
    # entries that aren't linked from the timeline view / document type entries
    get "/hidden_entries"
    assert_response 200

    # i expect exactly two links:
    assert_equal 2, css_select("a").count
    assert_select "a[href='/youvechanged.jpg']"
    assert_select "a[href='/about.html']"

    # try getting individual pages:
    get "/2021/should-just-work.html"
    assert_response 200

    get "/2021-07-06-convention-over-configuration"
    assert_response 200

    get "/musings.html"
    assert_response 200

    get "/about.html"
    assert_response 200

    # and now we test the document:

    get "/youvechanged.jpg"
    # we get redirected to the blobs path
    assert_response 302

    get response.location
    # we get redirected to the signed service url
    assert_response 302

    get response.location
    # we finally get the content:
    assert_response 200
    assert_equal "image/jpeg", response.content_type

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
