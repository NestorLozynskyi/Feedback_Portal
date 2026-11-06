require "test_helper"

class SuggestionTest < ActiveSupport::TestCase
  def valid_attrs
    { title: "Calendar view for tasks", body: "A month view would really help planning.", kind: "feature", category: categories(:ui), author: users(:maya) }
  end

  test "new suggestion is Under Review" do
    s = Suggestion.create!(valid_attrs)
    assert_equal "under_review", s.status
    assert_not s.edited?
  end

  test "title length 8..120 and description at least 20" do
    s = Suggestion.new(valid_attrs.merge(title: "Short", body: "Too short"))
    assert_not s.valid?(:form)
    assert_includes s.errors[:title], "Make the title at least 8 characters so people can understand it."
    assert_includes s.errors[:body], "Add a bit more detail — at least 20 characters."
    s.title = "x" * 121
    assert_not s.valid?
    assert_includes s.errors[:title], "Use 120 characters or fewer."
    s.title = "x" * 120
    s.body = "y" * 20
    assert s.valid?(:form)
  end

  test "type is one of the fixed set and category is required in the form" do
    s = Suggestion.new(valid_attrs.merge(kind: nil, category: nil))
    assert_not s.valid?(:form)
    assert_includes s.errors[:kind], "Choose a type: Idea, Feature Request or Bug Report."
    assert_includes s.errors[:category], "Choose a category."
    s.kind = "question"
    assert_not s.valid?
    assert s.errors[:kind].any?
    assert_equal %w[idea feature bug], Suggestion::KINDS.keys
    assert_equal %w[under_review planned in_progress completed declined], Suggestion::STATUSES.keys
  end

  test "editing content marks it Edited, status changes do not" do
    s = suggestions(:maya_review)
    s.update!(status: "planned")
    assert_not s.edited?
    s.update!(title: "Keyboard shortcuts for moving tasks quickly")
    assert s.edited?
  end

  test "visibility of hidden suggestions" do
    scope = ->(u) { Suggestion.visible_to(u) }
    hidden = suggestions(:maya_hidden)
    assert_not_includes scope.(nil), hidden
    assert_not_includes scope.(users(:priya)), hidden
    assert_includes scope.(users(:maya)), hidden
    assert_includes scope.(users(:admin)), hidden
    assert_not hidden.visible_to?(nil)
    assert hidden.visible_to?(users(:maya))
  end

  test "participation: signed in, not blocked, not hidden" do
    s = suggestions(:priya_planned)
    assert_not s.open_for_participation_by?(nil)
    assert_not s.open_for_participation_by?(users(:jordan))
    assert s.open_for_participation_by?(users(:maya))
    assert_not suggestions(:maya_hidden).open_for_participation_by?(users(:admin))
  end

  test "editing and deleting: author only, not blocked, not hidden; admin may delete" do
    own = suggestions(:maya_review)
    assert own.editable_by?(users(:maya))
    assert_not own.editable_by?(users(:priya))
    assert_not own.editable_by?(users(:admin))
    assert own.deletable_by?(users(:admin))
    assert_not own.deletable_by?(users(:priya))
    assert_not suggestions(:maya_hidden).editable_by?(users(:maya))
    assert_not suggestions(:maya_hidden).deletable_by?(users(:maya))
    assert_not suggestions(:jordan_completed).editable_by?(users(:jordan))
  end

  test "roadmap contains only Planned, In Progress and Completed" do
    statuses = Suggestion.on_roadmap.distinct.pluck(:status).sort
    assert_equal %w[completed in_progress planned], statuses
    assert_not_includes Suggestion.visible_to(nil).on_roadmap, suggestions(:maya_hidden)
  end

  test "deleting a suggestion removes its votes and comments" do
    s = suggestions(:priya_planned)
    assert_difference -> { Vote.count } => -2, -> { Comment.count } => -5 do
      s.destroy!
    end
  end

  test "sorting newest first and by votes" do
    assert_equal suggestions(:maya_hidden), Suggestion.newest_first.first
    assert_equal suggestions(:priya_planned), Suggestion.most_voted_first.first
  end
end
