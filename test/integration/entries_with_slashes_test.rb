require 'test_helper'

class EntriesWithSlashesTest < ActionDispatch::IntegrationTest
  setup do
    @current_notebook = Notebook.create(name: "test-notebook")
  end

  test "entries with slashes in their identifier can be saved to disk, and read from disk" do
    if Arquivo.static?
      return
    end

    enable_local_sync do
      arquivo_path = Setting.get(:arquivo, :arquivo_path)
      entry = @current_notebook.entries.create(identifier: "hello/world", body: "this is my test entry")

      assert_equal 1, @current_notebook.entries.count
      assert_equal "hello-world", entry.identifier_sanitized

      assert File.exist?(entry.to_full_file_path(arquivo_path))

      # let's test that importing works just fine, thanks
      # delete should not touch the actual file persisted to disk
      entry.delete
      assert_equal 0, @current_notebook.entries.count

      syncer = SyncFromDisk.new(@current_notebook.to_folder_path)
      syncer.import!
      assert_equal 1, @current_notebook.entries.count

      assert_equal "this is my test entry", @current_notebook.entries.last.body

      # --
      # what about more malicious identifier names?
      hax_identifier = "../../../../../lol.wtf"
      entry = @current_notebook.entries.create(identifier: hax_identifier, body: "haxx u")

      # if we resolve the all ..s we walk out of the arquivo folder path
      hax_path = File.realdirpath(File.join(arquivo_path, hax_identifier))
      # and the original "mother" top-level folder is no longer in the path
      refute hax_path.index(arquivo_path)

      # but we sanitize file names so we don't have this issue:
      real_entry_path = File.realdirpath(entry.to_full_file_path(arquivo_path))
      assert real_entry_path.index(arquivo_path)
      assert File.exist?(real_entry_path)
    end
  end

  test "entries with slashes in their identifier render properly, and can be navigated to and fro" do
    enable_local_sync do
      entries = [@current_notebook.entries.create(identifier: "hello", body: "entry 1"),
                 @current_notebook.entries.create(identifier: "hello/world", body: "entry 2", in_reply_to: "hello"),
                 @current_notebook.entries.create(identifier: "hello/world/layers", body: "entry 3", in_reply_to: "hello/world"),
                 @current_notebook.entries.create(identifier: "hello/world/more.html", body: "entry 4", in_reply_to: "hello/world/layers")]

      assert_equal 4, @current_notebook.entries.count

      # we can see the links in the timeline
      get timeline_path(@current_notebook)
      assert_response :success

      expected_hrefs = entries.map { |e| entry_path(e) }.to_set
      permalink_hrefs = css_select("a.permalink[href]").map do |a| a["href"] end.to_set

      assert_equal expected_hrefs, permalink_hrefs

      # we can navigate to the show action
      get entry_path(entries.last)
      assert_response :success

      if Arquivo.static?
        assert_select("entry-subject", html: /#{entries.last.identifier}/)
        assert_select("entry-body", text: entries.last.body)
      else
        # the page displays and lists the identifier name in the timeline top thingy
        assert_select("nav li[aria-current=page] h3", text: entries.last.identifier)
        # and we're looking at the same right page
        assert_select(".entry-body", text: entries.last.body)
      end

      # we can edit it:
      if !Arquivo.static?
        get edit_entry_path(entries.last)
        assert_response :success
        assert_select("textarea#entry_body", text: entries.last.body)

        # we can see its thread
        get threaded_entry_path(entries.last)
        assert_response :success

        threaded_permalink_hrefs = css_select("a.permalink[href]").map do |a| a["href"] end.to_set
        assert_equal expected_hrefs, threaded_permalink_hrefs
      end

      # ran out of time, but feel confident about where we're at, so TODO:
      # - access /files/ path
      # - copy to another notebook
    end
  end
end
