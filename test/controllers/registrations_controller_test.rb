require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "sign up creates a member and signs in" do
    get new_registration_path
    assert_response :success
    assert_difference(-> { User.count }, 1) do
      post registration_path, params: { user: { name: "Nora Quinn", email_address: "nora@example.com", password: "longpassword" } }
    end
    user = User.find_by!(email_address: "nora@example.com")
    assert_not user.admin?
    assert_not user.blocked?
    assert_redirected_to root_url
    assert cookies[:session_id]
  end

  test "sign up cannot make an admin" do
    post registration_path, params: { user: { name: "Eve", email_address: "eve@example.com", password: "longpassword", admin: true } }
    assert_not User.find_by!(email_address: "eve@example.com").admin?
  end

  test "sign up errors" do
    assert_no_difference(-> { User.count }) do
      post registration_path, params: { user: { name: "", email_address: "maya@example.com", password: "1234" } }
    end
    assert_response :unprocessable_entity
    assert_select ".error-summary-title", "There are 3 problems to fix"
    assert_select "#email-error", text: /already exists/
  end
end
