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

  test "performs basic markdown" do
    basic_markdown = <<~FOO
    # this is a header
    **this is bolded** and *this is italicized*
    [this is a link](example.com)
    <script>this gets sanitized out</script>
    <div data-random="foo">no attributes</div>
    FOO

    basic_markdown_html = @renderer.render_html(basic_markdown)
    assert_equal "<h1 data-sourcepos=\"1:1-1:18\">\n<a id=\"this-is-a-header\" class=\"anchor\" href=\"#this-is-a-header\" aria-hidden=\"true\"><span aria-hidden=\"true\" class=\"octicon octicon-link\"></span></a>this is a header</h1>\n<p data-sourcepos=\"2:1-3:29\"><strong>this is bolded</strong> and <em>this is italicized</em><br>\n<a href=\"example.com\">this is a link</a></p>\n&lt;script&gt;this gets sanitized out&lt;/script&gt;\n<div>no attributes</div>", basic_markdown_html
  end

  test "parses hashtags and links them" do
    hashtag_markdown = <<~FOO
    #foo bar #baz
    FOO

    hashtag_markdown_html = @renderer.render_html(hashtag_markdown)

    # of note: bar was not converted, and the generated urls
    # point to /test/timeline/search
    assert_equal "<p data-sourcepos=\"1:1-1:13\"> <a href=\"/phillmv/test/timeline/search?query=%23foo\">#foo</a> bar <a href=\"/phillmv/test/timeline/search?query=%23baz\">#baz</a></p>", hashtag_markdown_html
  end

  test "parses contacts and links them" do
    contact_markdown = <<~FOO
    @foo bar @baz
    FOO

    contact_markdown_html = @renderer.render_html(contact_markdown)
    # of note: bar is not converted,
    # it points to /test/timeline/search
    # .user_mention class
    assert_equal "<p data-sourcepos=\"1:1-1:13\"><a href=\"/phillmv/test/timeline/search?query=%40foo\" class=\"user-mention\">@foo</a> bar <a href=\"/phillmv/test/timeline/search?query=%40baz\" class=\"user-mention\">@baz</a></p>", contact_markdown_html
  end

  test "adds ids to headers" do
    header_markdown = <<~FOO
    # this is a title
    ## this is a subhead
    FOO


    header_markdown_html = @renderer.render_html(header_markdown)

    # of note here is the <a id="this-is-a-title"> and <a id="this-is-a-subhead">
    assert_equal "<h1 data-sourcepos=\"1:1-1:17\">\n<a id=\"this-is-a-title\" class=\"anchor\" href=\"#this-is-a-title\" aria-hidden=\"true\"><span aria-hidden=\"true\" class=\"octicon octicon-link\"></span></a>this is a title</h1>\n<h2 data-sourcepos=\"2:1-2:20\">\n<a id=\"this-is-a-subhead\" class=\"anchor\" href=\"#this-is-a-subhead\" aria-hidden=\"true\"><span aria-hidden=\"true\" class=\"octicon octicon-link\"></span></a>this is a subhead</h2>", header_markdown_html
  end


  test "images are max width" do
    image_markdown = <<~FOO
    ![image alt](foo.png)
    FOO

    image_markdown_html = @renderer.render_html(image_markdown)

    # of note here is the <img style="max-width:100%">
    assert_equal "<p data-sourcepos=\"1:1-1:21\"><a href=\"foo.png\" target=\"_blank\"><img src=\"foo.png\" alt=\"image alt\" style=\"max-width:100%;\"></a></p>", image_markdown_html
  end

  # describe "task lists" do
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

  # extremely half ass and tested indirectly, but this is a feature I support:
  test "we generate tocs" do
    empty_toc = <<-FOO
<table-of-contents />

# entry one
# entry two
    FOO

    empty_toc_html = @renderer.render_html(empty_toc)

    assert_equal "<table-of-contents><h2>Contents</h2>\n<ol class=\"table-of-contents\">\n<li><a href=\"#entry-one\">entry one</a></li>\n<li><a href=\"#entry-two\">entry two</a></li>\n</ol></table-of-contents>\n<h1 data-sourcepos=\"3:1-3:11\">\n<a id=\"entry-one\" class=\"anchor\" href=\"#entry-one\" aria-hidden=\"true\"><span aria-hidden=\"true\" class=\"octicon octicon-link\"></span></a>entry one</h1>\n<h1 data-sourcepos=\"4:1-4:11\">\n<a id=\"entry-two\" class=\"anchor\" href=\"#entry-two\" aria-hidden=\"true\"><span aria-hidden=\"true\" class=\"octicon octicon-link\"></span></a>entry two</h1>", empty_toc_html


    almost_empty_toc = <<-FOO
<table-of-contents></table-of-contents>

# entry one
# entry two
    FOO

    almost_empty_toc_html = @renderer.render_html(almost_empty_toc)

    assert_equal "<p data-sourcepos=\"1:1-1:39\"></p><table-of-contents><h2>Contents</h2>\n<ol class=\"table-of-contents\">\n<li><a href=\"#entry-one\">entry one</a></li>\n<li><a href=\"#entry-two\">entry two</a></li>\n</ol></table-of-contents>\n<h1 data-sourcepos=\"3:1-3:11\">\n<a id=\"entry-one\" class=\"anchor\" href=\"#entry-one\" aria-hidden=\"true\"><span aria-hidden=\"true\" class=\"octicon octicon-link\"></span></a>entry one</h1>\n<h1 data-sourcepos=\"4:1-4:11\">\n<a id=\"entry-two\" class=\"anchor\" href=\"#entry-two\" aria-hidden=\"true\"><span aria-hidden=\"true\" class=\"octicon octicon-link\"></span></a>entry two</h1>", almost_empty_toc_html

    custom_header_toc = <<-FOO
<table-of-contents>

# tabela de conteúdos

</table-of-contents>

# entry one
# entry two
    FOO

    custom_header_toc_html = @renderer.render_html(custom_header_toc)

    assert_equal "<table-of-contents>\n<h1 data-sourcepos=\"3:1-3:22\">tabela de conteúdos</h1>\n<ol class=\"table-of-contents\">\n<li><a href=\"#entry-one\">entry one</a></li>\n<li><a href=\"#entry-two\">entry two</a></li>\n</ol></table-of-contents>\n<h1 data-sourcepos=\"7:1-7:11\">\n<a id=\"entry-one\" class=\"anchor\" href=\"#entry-one\" aria-hidden=\"true\"><span aria-hidden=\"true\" class=\"octicon octicon-link\"></span></a>entry one</h1>\n<h1 data-sourcepos=\"8:1-8:11\">\n<a id=\"entry-two\" class=\"anchor\" href=\"#entry-two\" aria-hidden=\"true\"><span aria-hidden=\"true\" class=\"octicon octicon-link\"></span></a>entry two</h1>", custom_header_toc_html
  end
end
