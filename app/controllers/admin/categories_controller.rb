module Admin
  class CategoriesController < BaseController
    before_action :set_category, only: %i[edit update destroy]

    def index
      load_categories
    end

    def create
      @new_category = Category.new(name: params.dig(:category, :name))
      if @new_category.save
        respond_with_list("Category “#{@new_category.name}” added.")
      else
        respond_with_list(nil, status: :unprocessable_entity)
      end
    end

    def edit
      @editing = @category
      render partial: "admin/categories/category_frame", locals: { category: @category, editing: @category, count: @category.suggestions.count }
    end

    def update
      @category.name = params.dig(:category, :name)
      if @category.save
        respond_with_list("Category renamed to “#{@category.name}”.")
      else
        render partial: "admin/categories/category_frame", locals: { category: @category, editing: @category, count: @category.suggestions.count },
               status: :unprocessable_entity
      end
    end

    def destroy
      name = @category.name
      @category.destroy!
      respond_with_list("Category “#{name}” deleted.")
    end

    private
      def set_category
        @category = Category.find(params[:id])
      end

      def load_categories
        @categories = Category.ordered.to_a
        @counts = Suggestion.group(:category_id).count
      end

      def respond_with_list(message, status: :ok)
        load_categories
        respond_to do |format|
          format.turbo_stream do
            streams = [ turbo_stream.replace("categories_admin", partial: "admin/categories/admin", locals: { new_category: (@new_category unless message) }) ]
            streams << toast_stream(message) if message
            render turbo_stream: streams, status: status
          end
          format.html { redirect_to admin_categories_path, notice: message, status: :see_other }
        end
      end
  end
end
