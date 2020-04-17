require 'test_helper'

class CalendarControllerTest < ActionDispatch::IntegrationTest
  test "should get monthly" do
    get calendar_monthly_url
    assert_response :success
  end

  test "should get daily" do
    get calendar_daily_url
    assert_response :success
  end

end
