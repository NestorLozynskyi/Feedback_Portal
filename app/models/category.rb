class Category < ApplicationRecord
  has_many :suggestions, dependent: :nullify

  normalizes :name, with: ->(n) { n.squish }

  validates :name, presence: { message: "Enter a category name." },
                   length: { maximum: 40, message: "Use 40 characters or fewer." }
  validate :name_is_unique

  scope :ordered, -> { order(:id) }

  private
    def name_is_unique
      return if name.blank?
      clash = Category.where("lower(name) = ?", name.downcase).where.not(id: id)
      errors.add(:name, "A category with this name already exists.") if clash.exists?
    end
end
