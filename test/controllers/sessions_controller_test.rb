require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:maya) }

  test "new shows the reason" do
    get new_session_path(reason: "vote")
    assert_response :success
    assert_select ".notice-info", "Sign in to upvote suggestions."
  end

  test "sign in returns to the stored page" do
    get new_session_path(reason: "vote", return_to: suggestion_path(suggestions(:priya_planned)))
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    assert_redirected_to suggestion_path(suggestions(:priya_planned))
    assert cookies[:session_id]
  end

  test "external return_to is ignored" do
    get new_session_path(return_to: "https://evil.example.com/")
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    assert_redirected_to root_url
  end

  test "wrong credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }
    assert_response :unprocessable_entity
    assert_select ".notice-danger", text: /Incorrect email or password/
    assert_nil cookies[:session_id]
  end

  test "blocked user can sign in" do
    post session_path, params: { email_address: users(:jordan).email_address, password: "password123" }
    assert_redirected_to root_url
  end

  test "sign out" do
    sign_in_as @user
    delete session_path
    assert_redirected_to root_path
    assert_empty cookies[:session_id]
  end
end
