require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "name is required, up to 40 characters and unique ignoring case" do
    assert_includes Category.new(name: "").tap(&:valid?).errors[:name], "Enter a category name."
    assert_includes Category.new(name: "x" * 41).tap(&:valid?).errors[:name], "Use 40 characters or fewer."
    assert_includes Category.new(name: "ui/ux").tap(&:valid?).errors[:name], "A category with this name already exists."
    assert Category.new(name: "x" * 40).valid?
  end

  test "renaming to its own name is allowed" do
    assert categories(:ui).update(name: "UI/UX")
  end

  test "deleting a category keeps its suggestions as Uncategorized" do
    s = suggestions(:priya_progress)
    assert_no_difference -> { Suggestion.count } do
      categories(:performance).destroy!
    end
    s.reload
    assert_nil s.category
    assert_equal "Uncategorized", s.category_name
    assert_not s.edited?
  end
end
