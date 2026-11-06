class CommentsController < ApplicationController
  allow_unauthenticated_access only: %i[create edit destroy]
  before_action :set_suggestion
  before_action :set_comment, except: :create

  def create
    return unless require_participant("comment")
    return deny("Comments are closed while this suggestion is hidden.") if @suggestion.hidden?
    @new_comment = @suggestion.comments.new(author: current_user, body: params.dig(:comment, :body))
    if @new_comment.save
      respond_with_comments("Comment posted.")
    else
      respond_with_comments(nil, status: :unprocessable_entity)
    end
  end

  def edit
    return redirect_to(@suggestion) unless @comment.editable_by?(current_user)
    @editing = @comment
    render_comment_frame
  end

  def update
    return unless require_participant("comment")
    return deny("You can’t edit this comment.") unless @comment.editable_by?(current_user)
    if @comment.update(body: params.dig(:comment, :body))
      respond_with_comments("Comment updated.")
    else
      @editing = @comment
      render_comment_frame(status: :unprocessable_entity)
    end
  end

  def destroy
    return redirect_to(new_session_path, status: :see_other) unless current_user
    unless @comment.deletable_by?(current_user)
      return deny(current_user.blocked? ? "Your account is restricted, so this action is unavailable." : "You can’t delete this comment.")
    end
    @comment.destroy!
    respond_with_comments("Comment deleted.")
  end

  def hide
    return deny("Only the admin can moderate comments.") unless @comment.moderatable_by?(current_user)
    @comment.update!(hidden: true)
    respond_with_comments("Comment hidden. Only its author and admins can see it.")
  end

  def unhide
    return deny("Only the admin can moderate comments.") unless @comment.moderatable_by?(current_user)
    @comment.update!(hidden: false)
    respond_with_comments("Comment is visible to everyone again.")
  end

  private
    def set_suggestion
      @suggestion = Suggestion.includes(:author).find_by(id: params[:suggestion_id])
      render("suggestions/unavailable", status: :not_found) unless @suggestion&.visible_to?(current_user)
    end

    def set_comment
      @comment = @suggestion.comments.find_by(id: params[:id])
      render("suggestions/unavailable", status: :not_found) unless @comment&.visible_to?(current_user)
    end

    def load_comments
      @comments = @suggestion.comments.visible_to(current_user).includes(:author).chronological.to_a
    end

    def respond_with_comments(message, status: :ok)
      load_comments
      respond_to do |format|
        format.turbo_stream do
          streams = [ turbo_stream.replace("comments", partial: "comments/section", locals: { suggestion: @suggestion, comments: @comments, new_comment: (@new_comment unless message) }) ]
          streams << toast_stream(message) if message
          render turbo_stream: streams, status: status
        end
        format.html { redirect_to suggestion_path(@suggestion, anchor: "comments"), notice: message, status: :see_other }
      end
    end

    def render_comment_frame(status: :ok)
      render partial: "comments/comment_frame", locals: { comment: @comment, suggestion: @suggestion, editing: @editing }, status: status
    end
end
