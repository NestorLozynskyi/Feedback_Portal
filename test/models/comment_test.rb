require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "body is required with mockup messages" do
    c = Comment.new(suggestion: suggestions(:priya_planned), author: users(:maya), body: "  ")
    assert_not c.valid?
    assert_includes c.errors[:body], "Write a comment before posting."
    existing = comments(:maya_on_planned)
    existing.body = ""
    assert_not existing.valid?
    assert_includes existing.errors[:body], "A comment can’t be empty. Delete it instead if you no longer need it."
  end

  test "editing marks Edited" do
    c = comments(:maya_on_planned)
    assert_not c.edited?
    c.update!(body: "Please keep label colors readable in dark mode.")
    assert c.edited?
  end

  test "hidden comments are visible only to the author and admin" do
    hidden = comments(:maya_hidden_on_planned)
    assert_not_includes Comment.visible_to(nil), hidden
    assert_not_includes Comment.visible_to(users(:priya)), hidden
    assert_includes Comment.visible_to(users(:maya)), hidden
    assert_includes Comment.visible_to(users(:admin)), hidden
  end

  test "edit rights: author, not blocked, comment and suggestion not hidden" do
    assert comments(:maya_on_planned).editable_by?(users(:maya))
    assert_not comments(:maya_on_planned).editable_by?(users(:priya))
    assert_not comments(:maya_hidden_on_planned).editable_by?(users(:maya))
    assert_not comments(:jordan_on_planned).editable_by?(users(:jordan))
    assert_not comments(:priya_on_hidden).editable_by?(users(:priya))
    assert_not comments(:priya_on_hidden).deletable_by?(users(:priya))
    assert comments(:priya_on_hidden).deletable_by?(users(:admin))
  end

  test "admin moderates other people's comments, not own" do
    assert comments(:maya_on_planned).moderatable_by?(users(:admin))
    assert_not comments(:admin_on_planned).moderatable_by?(users(:admin))
    assert_not comments(:priya_on_planned).moderatable_by?(users(:maya))
  end
end
