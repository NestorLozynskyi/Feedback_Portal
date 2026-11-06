class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    return redirect_to(root_path) if current_user
    session[:return_to_after_authenticating] = params[:return_to] if safe_return_path?(params[:return_to])
    @user = User.new
  end

  def create
    @user = User.new(params.expect(user: %i[name email_address password]))
    @user.password = "" if @user.password.nil? # so a blank password is reported
    if @user.save
      start_new_session_for @user
      redirect_to after_authentication_url, notice: "Welcome! Your account is ready."
    else
      render :new, status: :unprocessable_entity
    end
  end
end
