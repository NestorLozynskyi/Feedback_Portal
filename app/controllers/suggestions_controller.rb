class SuggestionsController < ApplicationController
  allow_unauthenticated_access only: %i[index show new edit]
  before_action :set_suggestion, only: %i[show edit update destroy status hide unhide]
  before_action :require_admin_action, only: %i[status hide unhide]

  def index
    @sort = params[:sort] == "votes" ? "votes" : "newest"
    scope = Suggestion.visible_to(current_user).includes(:category, :author)
    scope = @sort == "votes" ? scope.most_voted_first : scope.newest_first
    @suggestions = scope.to_a
    @comment_counts = comment_counts_for(@suggestions)
    @voted_ids = voted_ids_for(@suggestions)
  end

  def show
    return render_unavailable unless @suggestion.visible_to?(current_user)
    load_detail
  end

  def new
    @suggestion = Suggestion.new
    render_form_state || render(:form)
  end

  def create
    return unless require_participant("create")
    @suggestion = current_user.suggestions.new(suggestion_params.merge(status: "under_review"))
    if @suggestion.save(context: :form)
      redirect_to @suggestion, notice: "Suggestion published. Its status is Under Review.", status: :see_other
    else
      render :form, status: :unprocessable_entity
    end
  end

  def edit
    render_form_state || render(:form)
  end

  def update
    return unless require_participant("create")
    return render_unavailable unless @suggestion.visible_to?(current_user)
    return deny("Only the author can edit this suggestion.") unless @suggestion.editable_by?(current_user)
    @suggestion.assign_attributes(suggestion_params)
    if @suggestion.save(context: :form)
      redirect_to @suggestion, notice: "Changes saved.", status: :see_other
    else
      render :form, status: :unprocessable_entity
    end
  end

  def destroy
    return redirect_to(new_session_path, status: :see_other) unless current_user
    return render_unavailable unless @suggestion.visible_to?(current_user)
    unless @suggestion.deletable_by?(current_user)
      return deny(current_user.blocked? ? "Your account is restricted, so this action is unavailable." : "You can’t delete this suggestion.")
    end
    @suggestion.destroy!
    redirect_to root_path, notice: "Suggestion deleted.", status: :see_other
  end

  # Admin moderation
  def status
    new_status = params[:status].to_s
    return deny("Choose a valid status.", status: :unprocessable_entity) unless Suggestion::STATUSES.key?(new_status)
    message =
      if new_status == @suggestion.status
        "Status is already #{@suggestion.status_label}."
      else
        @suggestion.update!(status: new_status)
        "Status changed to #{@suggestion.status_label}."
      end
    respond_with_detail(message)
  end

  def hide
    @suggestion.update!(hidden: true)
    respond_with_detail("Suggestion hidden. Only the author and admins can see it.")
  end

  def unhide
    @suggestion.update!(hidden: false)
    respond_with_detail("Suggestion is visible to everyone again.")
  end

  private
    def set_suggestion
      @suggestion = Suggestion.includes(:category, :author).find_by(id: params[:id])
      render_unavailable unless @suggestion
    end

    def require_admin_action
      return if current_user&.admin?
      deny("Only the admin can moderate suggestions.")
    end

    def suggestion_params
      params.expect(suggestion: %i[title kind category_id body])
    end

    def render_unavailable
      render "suggestions/unavailable", status: :not_found
    end

    # Guest / restricted / non-author / hidden states of the create-edit form.
    def render_form_state
      @state =
        if !current_user then :guest
        elsif current_user.blocked? then :restricted
        elsif @suggestion.persisted? && !@suggestion.visible_to?(current_user) then :unavailable
        elsif @suggestion.persisted? && (!@suggestion.authored_by?(current_user) || @suggestion.hidden?) then :not_editable
        end
      return false unless @state
      return render_unavailable if @state == :unavailable
      render :form_state, status: (@state == :guest ? :ok : :forbidden)
    end

    def load_detail
      @comments = @suggestion.comments.visible_to(current_user).includes(:author).chronological.to_a
      @voted = @suggestion.voted_by?(current_user)
    end

    def respond_with_detail(message)
      load_detail
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [ turbo_stream.replace("suggestion_detail", partial: "suggestions/detail"), toast_stream(message) ]
        end
        format.html { redirect_to @suggestion, notice: message, status: :see_other }
      end
    end

    def comment_counts_for(suggestions)
      Comment.visible_to(current_user).where(suggestion_id: suggestions.map(&:id)).group(:suggestion_id).count
    end

    def voted_ids_for(suggestions)
      return Set.new unless current_user
      current_user.votes.where(suggestion_id: suggestions.map(&:id)).pluck(:suggestion_id).to_set
    end
end
