require 'test_helper'

class ServicesControllerTest < ActionController::TestCase
  test "should get select" do
    get :select
    assert_response :success
  end

  test "should get add" do
    get :add
    assert_response :success
  end

end
