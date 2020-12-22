require 'test_helper'

class EntryTaggerTest < ActiveSupport::TestCase
  setup do
    @notebook = Notebook.create(name: "test")
    @entry = @notebook.entries.create(body: "")
  end

  test "renders tasks" do
    # reminder to test the pipeline stuff that needs the entry
    renderer = EntryRenderer.new(@entry)

    task_html = renderer.render_html("- [ ] test task")

    # TODO: parse output and then assert properties as opposed to just literally
    # enshrining the current behaviour as static
    # but it gets us off the ground for now
    assert_equal "<ul data-sourcepos=\"1:1-1:15\" class=\"task-list\">\n<li data-sourcepos=\"1:1-1:15\" class=\"task-list-item\">\n<input type=\"checkbox\" class=\"task-list-item-checkbox\" disabled> test task</li>\n</ul>", task_html

    only_todo_html = renderer.render_html("foo\r\n\r\nbar\r\n- [ ] test task", todo_only: true)

    # keeps first line, foo
    # but discards second line, bar

    assert_equal "<p data-sourcepos=\"1:1-1:3\">foo</p>\n\n<ul data-sourcepos=\"4:1-4:15\" class=\"task-list\"><li data-sourcepos=\"4:1-4:15\" class=\"task-list-item\">\n<input type=\"checkbox\" class=\"task-list-item-checkbox\" disabled> test task</li></ul>", only_todo_html

    # doesn't render tasks inside code blocks
    code_html = renderer.render_html("```- [ ] test task```")
    assert_equal "<p data-sourcepos=\"1:1-1:21\"><code>- [ ] test task</code></p>", code_html

    # TODO: test that an li will get zapped, unless it has a task
  end
end
