class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :resume_session
  helper_method :current_user

  private
    def current_user
      Current.user
    end

    # Signed in and not blocked. Guests go to sign in with the reason; blocked users get 403.
    def require_participant(reason)
      unless current_user
        store_return_to
        redirect_to new_session_path(reason: reason), status: :see_other
        return false
      end
      return true if current_user.can_participate?
      deny("Your account is restricted, so this action is unavailable.")
      false
    end

    def require_admin
      return if current_user&.admin?
      render "shared/no_access", status: (current_user ? :forbidden : :unauthorized)
    end

    def deny(message, status: :forbidden)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.append("toasts", partial: "shared/toast", locals: { message: message, kind: :alert }), status: status }
        format.html { redirect_back_or_to root_path, alert: message, status: :see_other }
      end
    end

    def store_return_to
      path = (request.get? || request.head?) ? request.fullpath : request.referer
      session[:return_to_after_authenticating] = path if safe_return_path?(path)
    end

    def safe_return_path?(path)
      return false if path.blank?
      uri = URI.parse(path)
      return false if uri.host.present? && uri.host != request.host
      uri.path.start_with?("/") && !uri.path.start_with?("//")
    rescue URI::InvalidURIError
      false
    end

    def toast_stream(message)
      turbo_stream.append("toasts", partial: "shared/toast", locals: { message: message, kind: :notice })
    end
end
