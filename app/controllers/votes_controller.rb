class VotesController < ApplicationController
  allow_unauthenticated_access only: %i[create destroy]
  before_action :set_suggestion

  def create
    return unless require_participant("vote")
    return deny("Voting is unavailable on hidden suggestions.") if @suggestion.hidden?
    Vote.find_or_create_by!(user: current_user, suggestion: @suggestion)
    respond
  rescue ActiveRecord::RecordNotUnique
    respond
  end

  def destroy
    return unless require_participant("vote")
    return deny("Voting is unavailable on hidden suggestions.") if @suggestion.hidden?
    current_user.votes.where(suggestion: @suggestion).destroy_all
    respond
  end

  private
    def set_suggestion
      @suggestion = Suggestion.find_by(id: params[:suggestion_id])
      render("suggestions/unavailable", status: :not_found) unless @suggestion&.visible_to?(current_user)
    end

    def respond
      @suggestion.reload
      @voted = @suggestion.voted_by?(current_user)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: %w[compact large].map { |variant|
            turbo_stream.replace(helpers.dom_id(@suggestion, "vote_#{variant}"), partial: "votes/button",
                                 locals: { suggestion: @suggestion, voted: @voted, variant: variant })
          }
        end
        format.html { redirect_back_or_to @suggestion, status: :see_other }
      end
    end
end
