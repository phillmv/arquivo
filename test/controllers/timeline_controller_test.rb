require 'test_helper'

class TimelineControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get timeline_index_url
    assert_response :success
  end

end
