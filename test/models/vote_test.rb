require "test_helper"

class VoteTest < ActiveSupport::TestCase
  test "one vote per user and suggestion, with a counter cache" do
    s = suggestions(:priya_progress)
    assert_difference -> { s.reload.votes_count }, 1 do
      Vote.create!(user: users(:maya), suggestion: s)
    end
    dup = Vote.new(user: users(:maya), suggestion: s)
    assert_not dup.valid?
    assert_raises(ActiveRecord::RecordNotUnique) { dup.save!(validate: false) }
    assert_difference -> { s.reload.votes_count }, -1 do
      Vote.find_by!(user: users(:maya), suggestion: s).destroy!
    end
  end
end
