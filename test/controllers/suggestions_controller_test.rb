require "test_helper"

class SuggestionsControllerTest < ActionDispatch::IntegrationTest
  def form_params(overrides = {})
    { suggestion: { title: "Calendar view for tasks", kind: "feature", category_id: categories(:ui).id,
                    body: "A month view that shows tasks by due date." }.merge(overrides) }
  end

  # Board
  test "guest board hides hidden suggestions and counts only visible ones" do
    get root_path
    assert_response :success
    assert_select ".s-row", 5
    assert_select ".toolbar-count", "5 suggestions"
    assert_no_match "Pin a comment", response.body
    assert_select "a.vote[href*='reason=vote']"
    assert_select ".page-head-actions a[href*='reason=create']", text: /New suggestion/
  end

  test "author and admin see the hidden suggestion with its label; others do not" do
    sign_in_as users(:maya)
    get root_path
    assert_select ".s-row.is-hidden", 1
    assert_select ".s-row.is-hidden .badge-hidden", text: /Hidden by moderator/
    sign_out
    sign_in_as users(:admin)
    get root_path
    assert_select ".s-row", 6
    sign_out
    sign_in_as users(:priya)
    get root_path
    assert_select ".s-row", 5
  end

  test "comment counts on the board exclude hidden comments for others" do
    get root_path
    row = css_select("##{ActionView::RecordIdentifier.dom_id(suggestions(:priya_planned))} .meta-item").first
    assert_match(/\b4\b/, row.text)
    sign_in_as users(:maya)
    get root_path
    row = css_select("##{ActionView::RecordIdentifier.dom_id(suggestions(:priya_planned))} .meta-item").first
    assert_match(/\b5\b/, row.text)
  end

  test "board sorts by newest by default and by votes on request" do
    get root_path
    assert_equal "Keyboard shortcuts for moving tasks", css_select(".s-row-title a").first.text
    assert_select ".segmented a[aria-current=true]", "Newest"
    get root_path(sort: "votes")
    assert_equal "Dark mode for the mobile app", css_select(".s-row-title a").first.text
    assert_select ".segmented a[aria-current=true]", "Most votes"
  end

  test "restricted user sees the banner and disabled actions" do
    sign_in_as users(:jordan)
    get root_path
    assert_select ".banner", text: /Your account is restricted/
    assert_select ".page-head-actions button[disabled]", text: /New suggestion/
    assert_select "button.vote[disabled]", 5
  end

  test "empty board" do
    Suggestion.delete_all
    get root_path
    assert_select ".empty-title", "No suggestions yet"
  end

  # Detail
  test "hidden suggestion is unavailable to guests and other users" do
    get suggestion_path(suggestions(:maya_hidden))
    assert_response :not_found
    sign_in_as users(:priya)
    get suggestion_path(suggestions(:maya_hidden))
    assert_response :not_found
  end

  test "author sees own hidden suggestion without edit, vote or comment" do
    sign_in_as users(:maya)
    get suggestion_path(suggestions(:maya_hidden))
    assert_response :success
    assert_select ".notice-hidden", text: /Hidden by moderator/
    assert_select ".owner-actions", 0
    assert_select "button.vote[disabled]"
    assert_select ".notice", text: /Comments are closed/
  end

  test "admin sees moderation panel; others do not" do
    sign_in_as users(:admin)
    get suggestion_path(suggestions(:priya_planned))
    assert_select ".mod-card select[name=status] option", 5
    sign_out
    sign_in_as users(:maya)
    get suggestion_path(suggestions(:priya_planned))
    assert_select ".mod-card", 0
  end

  test "comment labels Author, Team and You" do
    sign_in_as users(:maya)
    get suggestion_path(suggestions(:priya_planned))
    assert_select "#comment-#{comments(:priya_on_planned).id} .tag", "Author"
    assert_select "#comment-#{comments(:admin_on_planned).id} .tag", "Team"
    assert_select "#comment-#{comments(:maya_on_planned).id} .tag", "You"
    assert_select "#comment-#{comments(:maya_hidden_on_planned).id}.is-hidden"
  end

  # Create
  test "guest is sent to sign in to create" do
    get new_suggestion_path
    assert_select "h1", "Sign in to share a suggestion"
    post suggestions_path, params: form_params
    assert_redirected_to new_session_path
  end

  test "member creates a suggestion that starts Under Review" do
    sign_in_as users(:maya)
    assert_difference -> { Suggestion.count }, 1 do
      post suggestions_path, params: form_params(status: "completed")
    end
    s = Suggestion.last
    assert_equal "under_review", s.status
    assert_equal users(:maya), s.author
    assert_redirected_to suggestion_path(s)
  end

  test "invalid suggestion shows errors" do
    sign_in_as users(:maya)
    assert_no_difference -> { Suggestion.count } do
      post suggestions_path, params: form_params(title: "Short", kind: "", category_id: "", body: "tiny")
    end
    assert_response :unprocessable_entity
    assert_select ".error-summary-title", "There are 4 problems to fix"
  end

  test "blocked user cannot create" do
    sign_in_as users(:jordan)
    get new_suggestion_path
    assert_response :forbidden
    assert_select "h1", "You can’t create suggestions"
    assert_no_difference -> { Suggestion.count } do
      post suggestions_path, params: form_params
    end
  end

  # Edit / delete
  test "author edits own suggestion and it is marked Edited" do
    sign_in_as users(:maya)
    s = suggestions(:maya_review)
    patch suggestion_path(s), params: form_params(title: "Keyboard shortcuts for columns")
    assert_redirected_to suggestion_path(s)
    assert s.reload.edited?
    assert_equal "Keyboard shortcuts for columns", s.title
  end

  test "non-author, admin, blocked author and hidden author cannot edit" do
    { priya: :maya_review, admin: :maya_review, jordan: :jordan_completed, maya: :maya_hidden }.each do |user, sug|
      sign_in_as users(user)
      s = suggestions(sug)
      patch suggestion_path(s), params: form_params(title: "Changed by someone else")
      assert_not_equal "Changed by someone else", s.reload.title, "#{user} should not edit #{sug}"
      sign_out
    end
  end

  test "edit form states" do
    sign_in_as users(:priya)
    get edit_suggestion_path(suggestions(:maya_review))
    assert_response :forbidden
    assert_select ".empty-text", "Only the author can edit a suggestion."
    sign_out
    sign_in_as users(:maya)
    get edit_suggestion_path(suggestions(:maya_hidden))
    assert_select ".empty-text", "It was hidden by a moderator, so editing is unavailable."
  end

  test "author deletes own suggestion; non-author cannot; admin can" do
    sign_in_as users(:priya)
    assert_no_difference(-> { Suggestion.count }) { delete suggestion_path(suggestions(:maya_review)) }
    sign_out
    sign_in_as users(:maya)
    assert_difference(-> { Suggestion.count }, -1) { delete suggestion_path(suggestions(:maya_review)) }
    sign_out
    sign_in_as users(:admin)
    assert_difference(-> { Suggestion.count }, -1) { delete suggestion_path(suggestions(:maya_hidden)) }
  end

  test "blocked author and hidden author cannot delete" do
    sign_in_as users(:jordan)
    assert_no_difference(-> { Suggestion.count }) { delete suggestion_path(suggestions(:jordan_completed)) }
    sign_out
    sign_in_as users(:maya)
    assert_no_difference(-> { Suggestion.count }) { delete suggestion_path(suggestions(:maya_hidden)) }
  end

  # Moderation
  test "only admin changes status, hides and unhides" do
    s = suggestions(:maya_review)
    sign_in_as users(:maya)
    patch status_suggestion_path(s), params: { status: "planned" }, headers: TURBO
    assert_response :forbidden
    patch hide_suggestion_path(s), headers: TURBO
    assert_response :forbidden
    assert_equal "under_review", s.reload.status
    assert_not s.hidden?
    sign_out

    sign_in_as users(:admin)
    patch status_suggestion_path(s), params: { status: "planned" }, headers: TURBO
    assert_response :success
    assert_match "Status changed to Planned.", response.body
    assert_equal "planned", s.reload.status
    patch status_suggestion_path(s), params: { status: "bogus" }, headers: TURBO
    assert_response :unprocessable_entity
    patch hide_suggestion_path(s), headers: TURBO
    assert s.reload.hidden?
    patch unhide_suggestion_path(s), headers: TURBO
    assert_not s.reload.hidden?
  end

  test "guest cannot moderate" do
    patch hide_suggestion_path(suggestions(:maya_review))
    assert_redirected_to new_session_path
    assert_not suggestions(:maya_review).reload.hidden?
  end
end
