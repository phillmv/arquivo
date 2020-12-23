require 'test_helper'

class TodoListMakerTest < ActiveSupport::TestCase
  setup do
    @notebook = Notebook.create(name: "test")
  end

  test "creating tasks generates todolistitems" do
    body_md = <<~FOO
    some text here

    - [ ] a list
    - [x] completed
    FOO

    assert_equal 0, TodoListItem.count
    entry = @notebook.entries.create(body: body_md)

    assert_equal 2, TodoListItem.count
    assert_equal 1, TodoListItem.where(checked: true).count

    assert_equal 2, entry.todo_list.todo_list_items.count

    # it's idempotent
    TodoListMaker.new(entry).make!

    assert_equal 2, TodoListItem.count
    assert_equal 2, entry.todo_list.todo_list_items.count

    new_body_md = <<~FOO
    some text here

    - [ ] a list
    FOO

    entry.update(body: new_body_md)
    assert_equal 1, TodoListItem.count
    assert_equal 0, TodoListItem.where(checked: true).count
    assert_equal 1, entry.todo_list.todo_list_items.count

    new_new_body_md = <<~FOO
    some text here

    - [x] a list
    FOO


    entry.update(body: new_new_body_md)
    assert_equal 1, TodoListItem.count
    assert_equal 1, TodoListItem.where(checked: true).count
  end
end
