class RoadmapController < ApplicationController
  allow_unauthenticated_access

  def show
    suggestions = Suggestion.visible_to(current_user).on_roadmap.includes(:category).most_voted_first.to_a
    @columns = Suggestion::ROADMAP_STATUSES.index_with { |st| suggestions.select { |s| s.status == st } }
    @comment_counts = Comment.visible_to(current_user).where(suggestion_id: suggestions.map(&:id)).group(:suggestion_id).count
  end
end
