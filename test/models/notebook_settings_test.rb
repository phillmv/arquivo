class NotebookSettingsTest < ActiveSupport::TestCase
  setup do
    @notebook = Notebook.create(name: "main")
    Setting.delete_all
  end

  test "if a setting does not exist, use default site opt" do
    assert_equal "80", @notebook.settings.get(:port)
    assert_equal "example.com", @notebook.settings.get(:host)
  end

  test "if a setting does exist, return that. else, return nil" do
    @notebook.settings.set(:port, 443)
    @notebook.settings.set(:host, "example.okayfail.com")
    assert_equal "443", @notebook.settings.get(:port)
    assert_equal "example.okayfail.com", @notebook.settings.get(:host)

    assert_nil @notebook.settings.get(:foo)
  end

  test "a setting may be updated" do
    @notebook.settings.set(:custom, "my string")
    assert_equal "my string", @notebook.settings.get(:custom)

    @notebook.settings.set(:custom, "a different string")
    assert_equal "a different string", @notebook.settings.get(:custom)
  end

  test "if there are no render options, return {}" do
    assert_equal Hash.new, @notebook.settings.render_options
  end

  test "but if there are render opts, normalize the keys" do
    @notebook.settings.set(:sanitize, true)
    @notebook.settings.set(:smart_punctuation, false)

    h = @notebook.settings.render_options
    assert_equal false, h[:smart_punctuation]
    assert_equal true, h[:sanitize]
  end
end
