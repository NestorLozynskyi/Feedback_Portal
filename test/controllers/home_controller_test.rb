require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "guest sees home page with guest status" do
    get root_path

    assert_response :success
    assert_select "[data-testid=auth-status]", /guest/
    assert_select "a[href=?]", new_session_path
  end

  test "signed-in user sees their email and sign out button" do
    user = users(:one)
    sign_in_as(user)

    get root_path

    assert_response :success
    assert_select "[data-testid=auth-status]", /Signed in as\s+#{Regexp.escape(user.email_address)}/
    assert_select "form[action=?] button", session_path, text: "Sign out"
  end
end
