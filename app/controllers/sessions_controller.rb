class SessionsController < ApplicationController
  REASONS = {
    "vote" => "Sign in to upvote suggestions.",
    "comment" => "Sign in to comment on suggestions.",
    "create" => "Sign in to share a suggestion.",
    "admin" => "Sign in to continue."
  }.freeze

  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: ENV.fetch("SIGNIN_RATE_LIMIT", 10).to_i, within: 3.minutes, only: :create,
             with: -> { redirect_to new_session_path, alert: "Too many attempts. Try again in a few minutes." }

  def new
    return redirect_to(root_path) if current_user
    session[:return_to_after_authenticating] = params[:return_to] if safe_return_path?(params[:return_to])
    @reason = REASONS[params[:reason]]
  end

  def create
    @email = params[:email_address].to_s.strip
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url, notice: "You’re signed in."
    else
      @invalid = true
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "You signed out.", status: :see_other
  end
end
