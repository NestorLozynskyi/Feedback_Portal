require "test_helper"

class RoadmapControllerTest < ActionDispatch::IntegrationTest
  test "roadmap shows Planned, In Progress and Completed only, without hidden items for guests" do
    get roadmap_path
    assert_response :success
    assert_select ".rm-col", 3
    assert_select "#col-planned .rm-card", 1
    assert_select "#col-in-progress .rm-card", 1
    assert_select "#col-completed .rm-card", 1
    assert_no_match "Offline mode", response.body        # Declined
    assert_no_match "Keyboard shortcuts", response.body  # Under Review
    assert_no_match "Pin a comment", response.body       # hidden
    assert_select "#col-planned .rm-col-title .count-pill", "1"
    assert_select "#col-planned .rm-card .rm-votes", text: /2 votes/
    assert_select "#col-planned .rm-card .rm-votes", text: /\A4 comments\z/
    assert_select ".rm-tabs .rm-tab", 3
  end

  test "author and admin see the hidden roadmap item with its label" do
    sign_in_as users(:maya)
    get roadmap_path
    assert_select "#col-planned .rm-card.is-hidden", 1
    assert_select "#col-planned .rm-col-title .count-pill", "2"
  end
end
