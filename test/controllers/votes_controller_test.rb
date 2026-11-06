require "test_helper"

class VotesControllerTest < ActionDispatch::IntegrationTest
  setup { @s = suggestions(:priya_progress) }

  test "guest is sent to sign in with the vote reason" do
    post suggestion_vote_path(@s)
    assert_redirected_to new_session_path(reason: "vote")
    assert_equal 0, @s.reload.votes_count
  end

  test "one upvote per user, and it can be removed" do
    sign_in_as users(:maya)
    post suggestion_vote_path(@s), headers: TURBO
    assert_response :success
    assert_match "Upvoted", response.body
    post suggestion_vote_path(@s), headers: TURBO
    assert_equal 1, @s.reload.votes_count
    assert_equal 1, @s.votes.count
    delete suggestion_vote_path(@s), headers: TURBO
    assert_equal 0, @s.reload.votes_count
  end

  test "blocked user cannot vote but keeps existing votes" do
    sign_in_as users(:jordan)
    post suggestion_vote_path(@s), headers: TURBO
    assert_response :forbidden
    delete suggestion_vote_path(suggestions(:priya_planned)), headers: TURBO
    assert_response :forbidden
    assert Vote.exists?(user: users(:jordan), suggestion: suggestions(:priya_planned))
  end

  test "nobody votes on a hidden suggestion" do
    sign_in_as users(:admin)
    post suggestion_vote_path(suggestions(:maya_hidden)), headers: TURBO
    assert_response :forbidden
    sign_out
    sign_in_as users(:priya)
    post suggestion_vote_path(suggestions(:maya_hidden)), headers: TURBO
    assert_response :not_found
    assert_equal 0, suggestions(:maya_hidden).reload.votes_count
  end
end
