class Comment < ApplicationRecord
  belongs_to :suggestion
  belongs_to :author, class_name: "User"

  normalizes :body, with: ->(b) { b.strip.gsub("\r\n", "\n") }

  validates :body, presence: { message: "Write a comment before posting." }, on: :create
  validates :body, presence: { message: "A comment can’t be empty. Delete it instead if you no longer need it." }, on: :update
  validates :body, length: { maximum: 2000, message: "Use 2000 characters or fewer." }

  before_update :mark_edited, if: :will_save_change_to_body?

  scope :chronological, -> { order(:created_at, :id) }

  # Hidden comments are visible only to their author and the admin.
  def self.visible_to(user)
    return all if user&.admin?
    return where(hidden: false) unless user
    where(hidden: false).or(where(author_id: user.id))
  end

  def visible_to?(user)
    !hidden? || (user.present? && (user.admin? || author_id == user.id))
  end

  def authored_by?(user)
    user.present? && author_id == user.id
  end

  # The author edits/deletes while not blocked and neither the comment nor its suggestion is hidden.
  def editable_by?(user)
    authored_by?(user) && user.can_participate? && !hidden? && !suggestion.hidden?
  end

  def deletable_by?(user)
    return false unless user
    user.admin? || editable_by?(user)
  end

  # The admin moderates other people's comments.
  def moderatable_by?(user)
    user.present? && user.admin? && !authored_by?(user)
  end

  def edited? = edited_at.present?

  def paragraphs
    body.to_s.split(/\n{2,}/)
  end

  private
    def mark_edited
      self.edited_at = Time.current
    end
end
