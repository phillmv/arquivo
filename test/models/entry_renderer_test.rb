require 'test_helper'

class EntryRendererTest < ActiveSupport::TestCase
=begin
  # -- uncomment to enable assert_select, etc
  include Rails::Dom::Testing::Assertions::SelectorAssertions

  attr_accessor :document_root_element

  # this method allows us to use the assert_select assertion
  # but is it actually worth doing this?
  # what do i gain over just testing the actual html output, for now at least?
  def render_html(renderer, str)
    html = renderer.render_html(str)
    @document_root_element = Nokogiri::HTML::Document.parse(html)
    html
  end
=end

  setup do
    @notebook = Notebook.create(name: "test")
    @entry = @notebook.entries.create(body: "")
    @renderer = EntryRenderer.new(@entry)
  end

  context "task lists" do
    test "renders tasks" do
      # reminder to test the pipeline stuff that needs the entry

      task_example = <<~FOO
      - [ ] test task
      FOO
      task_html = @renderer.render_html(task_example)

      # not sure that this is the best approach, i.e. we're just enshrining
      # the current returned html as static
      # but it gets us off the ground for now
      #
      # meaningful attributes here:
      # ul[data-sourcepos], .task-list
      # li[data-sourcepos].task-list-item
      # input[type=checkbox].task-list-item-checkbox
      assert_equal "<ul data-sourcepos=\"1:1-1:15\" class=\"task-list\">\n<li data-sourcepos=\"1:1-1:15\" class=\"task-list-item\">\n<input type=\"checkbox\" class=\"task-list-item-checkbox\" disabled> test task</li>\n</ul>", task_html

      # but doesn't render tasks if they're in a code block
      code_example = <<~FOO
      ```- [ ] test task```
      FOO
      code_html = @renderer.render_html(code_example)

      # relevant fact here is NO ul, li is generated
      assert_equal "<p data-sourcepos=\"1:1-1:21\"><code>- [ ] test task</code></p>", code_html

    end

    test "only_todo flag trims excess text" do
      only_todo = <<~FOO
      foo

      bar

      - [ ] test task

      more text here
      FOO
      only_todo_html = @renderer.render_html(only_todo, todo_only: true)

      # keeps first line, foo
      # but discards second line, bar, and line after the task
      # otherwise, renders a full ul[data-sourcepos].task-list etc

      assert_equal "<p data-sourcepos=\"1:1-1:3\">foo</p>\n\n<ul data-sourcepos=\"5:1-6:0\" class=\"task-list\"><li data-sourcepos=\"5:1-6:0\" class=\"task-list-item\">\n<input type=\"checkbox\" class=\"task-list-item-checkbox\" disabled> test task</li></ul>\n", only_todo_html


      nested_list_example = <<~FOO
      - this is a list, and should be kept because
      - [ ] it has a nested task
      - this item will also be kept cos its li is attached to the ul with the nested task


      different text
      - this is a separate list tho, and will get removed
      FOO

      nested_list_html = @renderer.render_html(nested_list_example, todo_only: true)

      assert_equal "<ul data-sourcepos=\"1:1-5:0\" class=\"task-list\">\n<li data-sourcepos=\"1:1-1:44\">this is a list, and should be kept because</li>\n<li data-sourcepos=\"2:1-2:26\" class=\"task-list-item\">\n<input type=\"checkbox\" class=\"task-list-item-checkbox\" disabled> it has a nested task</li>\n<li data-sourcepos=\"3:1-5:0\">this item will also be kept cos its li is attached to the ul with the nested task</li>\n</ul>\n\n", nested_list_html

      # TODO: MyTaskListFilter has a lot of branching
      # for so little testing; need to follow up with more
      # of the cases where nodes get deleted.
    end
  end
end
