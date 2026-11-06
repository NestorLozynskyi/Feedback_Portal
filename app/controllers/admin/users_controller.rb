module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[block unblock]

    def index
      load_users
    end

    def block
      return deny("The admin can’t be blocked.") if @user.admin?
      @user.block!
      respond_with_table("#{@user.name} is blocked.")
    end

    def unblock
      @user.unblock!
      respond_with_table("#{@user.name} is unblocked.")
    end

    private
      def set_user
        @user = User.find(params[:id])
      end

      def load_users
        @users = User.by_name.to_a
        @suggestion_counts = Suggestion.group(:author_id).count
      end

      def respond_with_table(message)
        load_users
        respond_to do |format|
          format.turbo_stream { render turbo_stream: [ turbo_stream.replace("users_table", partial: "admin/users/table"), toast_stream(message) ] }
          format.html { redirect_to admin_users_path, notice: message, status: :see_other }
        end
      end
  end
end
