require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "sign-up validations use the mockup messages" do
    user = User.new(name: "", email_address: "maya@example", password: "1234")
    assert_not user.valid?
    assert_includes user.errors[:name], "Enter your name."
    assert_includes user.errors[:email_address], "Enter an email address like name@example.com."
    assert_includes user.errors[:password], "Use at least 8 characters for your password."
  end

  test "email must be unique case-insensitively" do
    user = User.new(name: "Copy", email_address: "MAYA@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "An account with this email already exists. Sign in instead."
  end

  test "there is only one admin" do
    other = users(:maya)
    other.admin = true
    assert_not other.valid?
    assert_raises(ActiveRecord::RecordNotUnique) { other.save!(validate: false) }
  end

  test "blocked users cannot participate and the admin cannot be blocked" do
    assert_not users(:jordan).can_participate?
    assert users(:maya).can_participate?
    assert_raises(ArgumentError) { users(:admin).block! }
    users(:maya).block!
    assert users(:maya).reload.blocked?
    users(:maya).unblock!
    assert users(:maya).reload.can_participate?
  end

  test "blocking keeps the user's content and votes" do
    maya = users(:maya)
    assert_no_difference -> { maya.suggestions.count + maya.comments.count + maya.votes.count } do
      maya.block!
    end
  end
end
