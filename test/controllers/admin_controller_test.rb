require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  test "guest and non-admin see no access" do
    get admin_categories_path
    assert_response :unauthorized
    assert_select "h1", "Sign in to continue"
    sign_in_as users(:maya)
    get admin_users_path
    assert_response :forbidden
    assert_select "h1", "You don’t have access to this page"
    post admin_categories_path, params: { category: { name: "Mobile" } }, headers: TURBO
    assert_response :forbidden
    patch block_admin_user_path(users(:priya)), headers: TURBO
    assert_not users(:priya).reload.blocked?
  end

  test "admin adds, renames and validates categories" do
    sign_in_as users(:admin)
    get admin_categories_path
    assert_select ".cat-list li", 3
    post admin_categories_path, params: { category: { name: "Mobile" } }, headers: TURBO
    assert Category.exists?(name: "Mobile")
    post admin_categories_path, params: { category: { name: "mobile" } }, headers: TURBO
    assert_response :unprocessable_entity
    assert_match "A category with this name already exists.", response.body
    post admin_categories_path, params: { category: { name: "x" * 41 } }, headers: TURBO
    assert_match "Use 40 characters or fewer.", response.body
    cat = Category.find_by!(name: "Mobile")
    patch admin_category_path(cat), params: { category: { name: "Mobile apps" } }, headers: TURBO
    assert_equal "Mobile apps", cat.reload.name
  end

  test "admin deletes a category that has suggestions; they become Uncategorized" do
    sign_in_as users(:admin)
    get admin_categories_path
    assert_select "form[action='#{admin_category_path(categories(:performance))}'][data-confirm-body-value*='2 suggestions use this category']"
    delete admin_category_path(categories(:performance)), headers: TURBO
    assert_response :success
    assert_equal 6, Suggestion.count
    assert_nil suggestions(:priya_progress).reload.category_id
    get root_path
    assert_select ".chip", text: /Uncategorized/
  end

  test "admin blocks and unblocks users but not the admin" do
    sign_in_as users(:admin)
    get admin_users_path
    assert_select ".dtable tbody tr", 4
    patch block_admin_user_path(users(:maya)), headers: TURBO
    assert users(:maya).reload.blocked?
    assert_match "Maya Chen is blocked.", response.body
    patch unblock_admin_user_path(users(:maya)), headers: TURBO
    assert_not users(:maya).reload.blocked?
    patch block_admin_user_path(users(:admin)), headers: TURBO
    assert_response :forbidden
    assert_not users(:admin).reload.blocked?
  end

  test "unblock restores rights" do
    sign_in_as users(:admin)
    patch unblock_admin_user_path(users(:jordan)), headers: TURBO
    sign_out
    sign_in_as users(:jordan)
    post suggestion_vote_path(suggestions(:priya_progress)), headers: TURBO
    assert_response :success
  end
end
