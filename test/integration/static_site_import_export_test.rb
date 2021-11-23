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

    notebook = load_and_assert_notebook("simple_site")

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

    about_html = notebook.entries.notes.find_by!(identifier: "about")
    # even tho it is an html file, we can set attributes thru its frontmatter
    # yaml, in this case the hide attribute. additional keys get dumped into
    # the metadata attribute.
    #
    # also, the contents of the file get stuffed into the body attribute
    assert about_html.hide
    assert_equal 1234, about_html.metadata["some_other_key"]
    assert_equal 0, about_html.body.index("<h1>Sample About Page</h1>")

    # we lop off .markdown extensions, we should have a 2021-07-06-convention-over-configuration
    # and its occurred at was defined in the filename.
    convention_over_conf = notebook.entries.notes.find_by!(identifier: "2021-07-06-convention-over-configuration")
    assert_equal DateTime.parse("Tue, 06 Jul 2021 00:00:00 UTC +00:00"), convention_over_conf.occurred_at

    # we lop off .markdown extensions, so we should have a musings.html
    musings = notebook.entries.notes.find_by!(identifier: "musings")

    # we lop off .md extensions, so we should have a yet-another-static-site
    # also, the date was defined in its front matter
    yass = notebook.entries.notes.find_by!(identifier: "yet-another-static-site")
    assert_equal DateTime.parse("2021-07-08"), yass.occurred_at

    # finally, the full folder path name becomes the identifier, so we should
    # also have a 2021/should-just-work.html
    should_just_work = notebook.entries.notes.find_by!(identifier: "2021/should-just-work")

    # ---
    # marvelous! let's go and test the properties of the default site that
    # gets generated with this content.
    # ---

    get "/"
    assert_response 200, "if this fails, ensure that the spring preloader isn't stuck loading tests in non-static mode"
    # the timeline lists at least a few of the entries
    assert_select "h1", text: "Things should Just Work."
    assert_select "h1", text: "Convention over configuration."
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
    assert_equal 3, css_select("a").count
    assert_select "a[href='/youvechanged.jpg']"
    assert_select "a[href='/about']"
    assert_select "a[href='/archive']"

    # try getting individual pages:
    get "/2021/should-just-work.html"
    assert_response 200
    assert_select "h1", text: "Things should Just Work."

    get "/2021-07-06-convention-over-configuration"
    assert_response 200
    assert_select "h1", text: "Convention over configuration."

    get "/musings.html"
    assert_response 200

    get "/about.html"
    assert_response 200

    # and now we test the document:

    get "/youvechanged.jpg"
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

  test "we can do all of the previous test, but also with tags and contacts" do
    if !Arquivo.static?
      puts "Not in static mode. Try again, with STATIC_PLS=true"
      return
    end

    notebook = load_and_assert_notebook("simple_site_with_contacts_and_tags")
    assert_equal 6, notebook.entries.count

    assert_equal 1, notebook.entries.documents.count
    assert_equal 5, notebook.entries.notes.count

    # the simple_site_with_contact_and_tags site has the same content as the
    # simple_site example, but here I added a few random tags and @mentions
    # I split these out into separate examples, because not everyone trying out
    # this app on the first time will neccessarily have tags or mentions
    # defined, and one early bug I'd encountered was the /tags link 500'ing

    assert_equal ["#convention", "#configuration", "#musings"].to_set,
                 notebook.tags.pluck(:name).to_set

    assert_equal ["phillmv", "youvechanged"].to_set,
                 notebook.contacts.pluck(:name).to_set

    get "/tags"
    assert_response 200
    assert_select "a[href='/tags/convention']"
    assert_select "a[href='/tags/configuration']"
    assert_select "a[href='/tags/musings']"

    get "/tags/convention"
    assert_response 200

    get "/contacts"
    assert_response 200
    assert_select "a[href='/contacts/phillmv']"
    assert_select "a[href='/contacts/youvechanged']"

    get "/contacts/phillmv"
    assert_response 200
  end

  test "we can override the default views when generating a static site" do
    if !Arquivo.static?
      puts "Not in static mode. Try again, with STATIC_PLS=true"
      return
    end

    notebook = load_and_assert_notebook("simple_site_with_custom_layouts")

    assert_equal 6, notebook.entries.count
    assert_equal 1, notebook.entries.documents.count
    assert_equal 5, notebook.entries.notes.count

    get "/2021/should-just-work.html"
    assert_response 200
    assert_select "h1", text: "Things should Just Work."
    assert_select "h1", text: "Custom template!!!!"

    get "/2021-07-06-convention-over-configuration"
    assert_response 200
    assert_select "h1", text: "Convention over configuration."
    assert_select "h1", text: "Custom template!!!!"

    get "/"
    assert_response 200
    assert_select "h1", text: "Custom timeline index!!!!"
  end

  test "we can provide custom .scss stylesheets, and they load!" do
    if !Arquivo.static?
      puts "Not in static mode. Try again, with STATIC_PLS=true"
      return
    end

    notebook = load_and_assert_notebook("simple_site_with_stylesheets")

    assert_equal 10, notebook.entries.count
    assert_equal 1, notebook.entries.manifests.count
    assert_equal 4, notebook.entries.documents.count
    assert_equal 5, notebook.entries.notes.count

    # so with this test i want to verify a few things:
    # - we found the stylesheets/application.css.scss and marked it as a manifest entry
    # - we're loading in the normalize.css file, ie other files in the
    # stylesheets/ folder will get sent down the pipe like any other attachment
    #   - as a side-effect, we don't do anything special to the non
    #   application.css.scss files
    # - finally, that the manifest application.css.scss generates a document-type
    # stylesheets/application.css entry
    #
    # the intention here is that if you're editing the layouts, you will add a stylesheet link
    # to your own css, which is rendered to a predictable spot.
    notebook.entries.manifests.find_by!(identifier: "stylesheets/application.css.scss")
    notebook.entries.documents.find_by!(identifier: "stylesheets/normalize.css")
    notebook.entries.documents.find_by!(identifier: "stylesheets/clearfix.scss")
    rendered_stylesheet = notebook.entries.documents.find_by!(identifier: "stylesheets/application.css")

    assert_equal 1, rendered_stylesheet.files.count
    assert rendered_stylesheet.hide

    # meanwhile, the raw manifest is available
    get "/stylesheets/application.css.scss"
    assert_response 200

    # and the rendered stylesheet will load:
    get "/stylesheets/application.css"

    assert_response 200
    assert_equal "text/css", response.content_type

    # in this case, application.css.scss is importing & including a clearfix
    # mixin, which adds an ::after pseudo-selector to the sample example style
    # this is a little hard to discern, so maybe in the future replace with a
    # better example.
    assert response.body.index("example::after"), "content should have been rendered"
  end

  test "in addition to stylesheets etc etc we also can provide configuration" do
    if !Arquivo.static?
      puts "Not in static mode. Try again, with STATIC_PLS=true"
      return
    end

    notebook = load_and_assert_notebook("simple_site_with_stylesheets_and_config")
    assert_equal 10, notebook.entries.count
    assert_equal 1, notebook.entries.manifests.count
    assert_equal 4, notebook.entries.documents.count
    assert_equal 5, notebook.entries.notes.count

    assert_equal "example.okayfail.com", notebook.settings.get(:host)
    assert_equal "Phillip Mendonça-Vieira", notebook.settings.get(:author_name)
    assert_equal "My amazing website!", notebook.settings.get(:title)
  end

  test "btw, feeds work (without config)" do
    notebook = load_and_assert_notebook("simple_site_with_stylesheets")

    get "/atom.xml"
    assert_response 200

    assert response.body.index("<id>http://example.com/atom.xml</id>"), "should have the default id"
    assert response.body.index("<link rel=\"alternate\" type=\"text/html\" href=\"http://example.com/\"/>\n  <link rel=\"self\" type=\"application/atom+xml\" href=\"http://example.com/atom.xml\"/>"), "should have the default links"
    assert response.body.index("<title>This is a default title.</title>"), "should have the default title"

    # actual content:
    assert response.body.index("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<feed xml:lang=\"en-US\" xmlns=\"http://www.w3.org/2005/Atom\""), "should look like an atom feed"
    assert response.body.index("<title>Designed to be flexible</title>"), "should contain the blog posts we've defined 1"
    assert response.body.index("<title>Convention over configuration.</title>"), "should contain the blog posts we've defined 2"
    assert response.body.index("<title>Things should Just Work.</title>"), "should contain the blog posts we've defined 3"
    assert response.body.index("<title>Yet Another Static Site Generator</title>"), "should contain the blog posts we've defined 4"

    refute response.body.index("<title>Sample About Page</title>"), "but hidden pages should not show up."

    get "/tags/convention/atom.xml"
    assert_response 200
    assert response.body.index("<id>http://example.com/tags/convention/atom.xml</id>"), "should have the default id"
    assert response.body.index("<link rel=\"alternate\" type=\"text/html\" href=\"http://example.com/tags/convention.html\"/>\n  <link rel=\"self\" type=\"application/atom+xml\" href=\"http://example.com/tags/convention/atom.xml\"/>"), "should have the right tag links"
    assert response.body.index("<title>This is a default title. (feed for #convention)</title>"), "should have the tag title"
    assert response.body.index("<title>Convention over configuration.</title>"), "should contain the blog posts with the tag 1"
    assert response.body.index("<title>Yet Another Static Site Generator</title>"), "should contain the blog posts with the tag 2"

    refute response.body.index("<title>Designed to be flexible</title>"), "should NOT contain the posts without the tag"

    get "/contacts/phillmv/atom.xml"
    assert_response 200
    assert response.body.index("<id>http://example.com/contacts/phillmv/atom.xml</id>"), "should have the default id"
    assert response.body.index("<link rel=\"alternate\" type=\"text/html\" href=\"http://example.com/contacts/phillmv.html\"/>\n  <link rel=\"self\" type=\"application/atom+xml\" href=\"http://example.com/contacts/phillmv/atom.xml\"/>"), "should have the right contact links"
    assert response.body.index("<title>This is a default title. (feed for @phillmv)</title>"), "should have the contact title"
    assert response.body.index("<title>Sample About Page</title>"), "should contain blog post with the contact name"
  end

  test "btw, feeds work (with config)" do
    notebook = load_and_assert_notebook("simple_site_with_stylesheets_and_config")

    get "/atom.xml"
    assert_response 200

    assert response.body.index("<id>http://example.okayfail.com/atom.xml</id>"), "should have the configured id"
    assert response.body.index("<link rel=\"alternate\" type=\"text/html\" href=\"http://example.okayfail.com/\"/>\n  <link rel=\"self\" type=\"application/atom+xml\" href=\"http://example.okayfail.com/atom.xml\"/>"), "should have the configured links"
    assert response.body.index("<title>My amazing website!</title>"), "should have the configured title"

    # actual content:
    assert response.body.index("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<feed xml:lang=\"en-US\" xmlns=\"http://www.w3.org/2005/Atom\""), "should look like an atom feed"
    assert response.body.index("<link rel=\"alternate\" type=\"text/html\" href=\"http://example.okayfail.com/2021/should-just-work.html\"/>"), "entries should have urls"

    assert response.body.index("<title>Designed to be flexible</title>"), "should contain the blog posts we've defined 1"
    assert response.body.index("<title>Convention over configuration.</title>"), "should contain the blog posts we've defined 2"
    assert response.body.index("<title>Things should Just Work.</title>"), "should contain the blog posts we've defined 3"
    assert response.body.index("<title>Yet Another Static Site Generator</title>"), "should contain the blog posts we've defined 4"

    refute response.body.index("<title>Sample About Page</title>"), "but hidden pages should not show up."

    get "/tags/convention/atom.xml"
    assert_response 200
    assert response.body.index("<id>http://example.okayfail.com/tags/convention/atom.xml</id>"), "should have the default id"
    assert response.body.index("<link rel=\"alternate\" type=\"text/html\" href=\"http://example.okayfail.com/tags/convention.html\"/>\n  <link rel=\"self\" type=\"application/atom+xml\" href=\"http://example.okayfail.com/tags/convention/atom.xml\"/>"), "should have the right tag links"
    assert response.body.index("<title>My amazing website! (feed for #convention)</title>"), "should have the tag title"
    assert response.body.index("<title>Convention over configuration.</title>"), "should contain the blog posts with the tag 1"
    assert response.body.index("<title>Yet Another Static Site Generator</title>"), "should contain the blog posts with the tag 2"

    refute response.body.index("<title>Designed to be flexible</title>"), "should NOT contain the posts without the tag"

    get "/contacts/phillmv/atom.xml"
    assert_response 200
    assert response.body.index("<id>http://example.okayfail.com/contacts/phillmv/atom.xml</id>"), "should have the default id"
    assert response.body.index("<link rel=\"alternate\" type=\"text/html\" href=\"http://example.okayfail.com/contacts/phillmv.html\"/>\n  <link rel=\"self\" type=\"application/atom+xml\" href=\"http://example.okayfail.com/contacts/phillmv/atom.xml\"/>"), "should have the right contact links"
    assert response.body.index("<title>My amazing website! (feed for @phillmv)</title>"), "should have the contact title"
    assert response.body.index("<title>Sample About Page</title>"), "should contain blog post with the contact name"
  end

  test "we can disable the contacts page" do
    if !Arquivo.static?
      puts "Not in static mode. Try again, with STATIC_PLS=true"
      return
    end

    notebook = load_and_assert_notebook("simple_site_with_contacts_and_tags")
    notebook.settings.set("disable_mentions", true)
    get "/contacts"
    assert_response 404

    get "/contacts/phillmv"
    assert_response 404

    get "/contacts/phillmv/atom.xml"
    assert_response 404
  end

  def load_and_assert_notebook(name)
    # let's establish that the system is empty
    assert_equal 0, Notebook.count
    assert_equal 0, Entry.count

    # and then we load in the simple_site content:
    notebook_path = File.join(Rails.root, "test/fixtures/static_sites/#{name}")
    SyncFromDisk.new(notebook_path).import!

    assert_equal 1, Notebook.count
    notebook = Notebook.last
    assert_equal name, notebook.name
    notebook
  end
end
