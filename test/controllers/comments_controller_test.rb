require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup { @s = suggestions(:priya_planned) }

  def comment_params(body) = { comment: { body: body } }

  test "guest is sent to sign in to comment" do
    post suggestion_comments_path(@s), params: comment_params("Hi")
    assert_redirected_to new_session_path(reason: "comment")
  end

  test "member posts a comment via Turbo Stream" do
    sign_in_as users(:maya)
    assert_difference(-> { @s.comments.count }, 1) do
      post suggestion_comments_path(@s), params: comment_params("Count me in."), headers: TURBO
    end
    assert_response :success
    assert_match "Comment posted.", response.body
    post suggestion_comments_path(@s), params: comment_params("  "), headers: TURBO
    assert_response :unprocessable_entity
    assert_match "Write a comment before posting.", response.body
  end

  test "blocked users and hidden suggestions block commenting" do
    sign_in_as users(:jordan)
    assert_no_difference(-> { Comment.count }) { post suggestion_comments_path(@s), params: comment_params("Hello"), headers: TURBO }
    assert_response :forbidden
    sign_out
    sign_in_as users(:maya)
    assert_no_difference(-> { Comment.count }) { post suggestion_comments_path(suggestions(:maya_hidden)), params: comment_params("Hello"), headers: TURBO }
    assert_response :forbidden
  end

  test "author edits own comment; others cannot" do
    c = comments(:maya_on_planned)
    sign_in_as users(:priya)
    patch suggestion_comment_path(@s, c), params: comment_params("Hijacked"), headers: TURBO
    assert_response :forbidden
    sign_out
    sign_in_as users(:maya)
    patch suggestion_comment_path(@s, c), params: comment_params("Edited text here."), headers: TURBO
    assert_response :success
    assert c.reload.edited?
    assert_match "Edited", response.body
  end

  test "blocked author cannot edit or delete own comment; hidden comment cannot be edited by its author" do
    sign_in_as users(:jordan)
    patch suggestion_comment_path(@s, comments(:jordan_on_planned)), params: comment_params("Changed"), headers: TURBO
    assert_response :forbidden
    delete suggestion_comment_path(@s, comments(:jordan_on_planned)), headers: TURBO
    assert_response :forbidden
    sign_out
    sign_in_as users(:maya)
    patch suggestion_comment_path(@s, comments(:maya_hidden_on_planned)), params: comment_params("Changed"), headers: TURBO
    assert_response :forbidden
  end

  test "comments in a hidden suggestion cannot be edited or deleted by their author" do
    sign_in_as users(:priya)
    c = comments(:priya_on_hidden)
    patch suggestion_comment_path(suggestions(:maya_hidden), c), params: comment_params("Changed"), headers: TURBO
    assert_response :not_found # Priya can't see the hidden suggestion at all
    sign_out
    sign_in_as users(:maya)
    assert_not c.editable_by?(users(:maya))
  end

  test "author deletes own comment" do
    sign_in_as users(:maya)
    assert_difference(-> { Comment.count }, -1) { delete suggestion_comment_path(@s, comments(:maya_on_planned)), headers: TURBO }
    assert_match "Comment deleted.", response.body
  end

  test "admin hides, unhides and deletes other people's comments" do
    c = comments(:priya_on_planned)
    sign_in_as users(:admin)
    patch hide_suggestion_comment_path(@s, c), headers: TURBO
    assert c.reload.hidden?
    patch unhide_suggestion_comment_path(@s, c), headers: TURBO
    assert_not c.reload.hidden?
    assert_difference(-> { Comment.count }, -1) { delete suggestion_comment_path(@s, c), headers: TURBO }
  end

  test "non-admin cannot hide comments" do
    sign_in_as users(:maya)
    patch hide_suggestion_comment_path(@s, comments(:priya_on_planned)), headers: TURBO
    assert_response :forbidden
    assert_not comments(:priya_on_planned).reload.hidden?
  end

  test "hidden comment is not shown to others" do
    sign_in_as users(:priya)
    get suggestion_path(@s)
    assert_select "#comment-#{comments(:maya_hidden_on_planned).id}", 0
    assert_select "#comments-title .count-pill", "4"
  end
end
