require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:maya) }

  test "new" do
    get new_password_path
    assert_response :success
  end

  test "create sends mail and shows the check-your-email state" do
    post passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_response :success
    assert_select "h1", "Check your email"
  end

  test "create for an unknown user sends no mail but shows the same state" do
    post passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_select "h1", "Check your email"
  end

  test "create with an invalid email" do
    post passwords_path, params: { email_address: "maya@example" }
    assert_response :unprocessable_entity
    assert_select "#email-error", text: /name@example.com/
  end

  test "edit" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
    assert_select ".auth-lead", "For #{@user.email_address}"
  end

  test "expired or invalid token shows the expired state" do
    get edit_password_path("invalid token")
    assert_response :unprocessable_entity
    assert_select "h1", "This reset link has expired"
  end

  test "update" do
    assert_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: { password: "newpassword", password_confirmation: "newpassword" }
    end
    assert_select "h1", "Password updated"
  end

  test "update validates length and confirmation" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "abc", password_confirmation: "abcd" }
    end
    assert_response :unprocessable_entity
    assert_select "#password-error", text: /at least 8 characters/
    assert_select "#password_confirmation-error", text: /don’t match/
  end
end
