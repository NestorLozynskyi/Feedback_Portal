class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: ENV.fetch("SIGNIN_RATE_LIMIT", 10).to_i, within: 3.minutes, only: :create,
             with: -> { redirect_to new_password_path, alert: "Too many attempts. Try again in a few minutes." }

  def new
  end

  def create
    @email = params[:email_address].to_s.strip
    unless @email.match?(User::EMAIL_FORMAT)
      @error = @email.blank? ? "Enter your email address." : "Enter an email address like name@example.com."
      return render :new, status: :unprocessable_entity
    end

    if user = User.find_by(email_address: @email.downcase)
      PasswordsMailer.reset(user).deliver_later
    end
    flash.now[:notice] = "We’ve sent another link." if params[:resend].present?
    render :sent
  end

  def edit
  end

  def update
    @password = params[:password].to_s
    @errors = []
    @errors << [ "password", @password.empty? ? "Enter a new password." : "Use at least 8 characters for your password." ] if @password.length < 8
    confirmation = params[:password_confirmation].to_s
    @errors << [ "password_confirmation", confirmation.empty? ? "Enter your new password again." : "Passwords don’t match. Enter the same password twice." ] if confirmation != @password || confirmation.empty?
    return render(:edit, status: :unprocessable_entity) if @errors.any?

    @user.update!(password: @password)
    @user.sessions.destroy_all
    render :updated
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
      render :expired, status: :unprocessable_entity
    end
end
