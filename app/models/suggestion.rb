class Suggestion < ApplicationRecord
  STATUSES = {
    "under_review" => { label: "Under Review", css: "under-review", desc: "The team is reviewing this suggestion." },
    "planned" => { label: "Planned", css: "planned", desc: "Accepted and scheduled. It appears on the public roadmap." },
    "in_progress" => { label: "In Progress", css: "in-progress", desc: "Currently being built. It appears on the public roadmap." },
    "completed" => { label: "Completed", css: "completed", desc: "Shipped and available. It appears on the public roadmap." },
    "declined" => { label: "Declined", css: "declined", desc: "The team doesn’t plan to work on this." }
  }.freeze
  ROADMAP_STATUSES = %w[planned in_progress completed].freeze

  KINDS = {
    "idea" => { label: "Idea", icon: :idea, desc: "A new concept or improvement to explore." },
    "feature" => { label: "Feature Request", icon: :feature, desc: "A specific capability you need." },
    "bug" => { label: "Bug Report", icon: :bug, desc: "Something isn’t working as expected." }
  }.freeze

  enum :status, STATUSES.keys.index_with(&:itself), validate: true
  enum :kind, KINDS.keys.index_with(&:itself), validate: { allow_nil: true }, prefix: true

  belongs_to :author, class_name: "User"
  belongs_to :category, optional: true
  has_many :votes, dependent: :delete_all
  has_many :voters, through: :votes, source: :user
  has_many :comments, dependent: :delete_all

  normalizes :title, with: ->(t) { t.squish }
  normalizes :body, with: ->(b) { b.strip.gsub("\r\n", "\n") }

  validates :title, presence: { message: "Enter a title for your suggestion." }
  validates :title, length: { minimum: 8, message: "Make the title at least 8 characters so people can understand it." }, allow_blank: true
  validates :title, length: { maximum: 120, message: "Use 120 characters or fewer." }
  validates :kind, presence: { message: "Choose a type: Idea, Feature Request or Bug Report." }
  # The form always requires a category; moderation updates of "Uncategorized" suggestions must still save.
  validates :category, presence: { message: "Choose a category." }, on: :form
  validates :body, presence: { message: "Describe your suggestion." }
  validates :body, length: { minimum: 20, message: "Add a bit more detail — at least 20 characters." }, allow_blank: true
  validates :body, length: { maximum: 5000, message: "Use 5000 characters or fewer." }

  before_update :mark_edited, if: -> { will_save_change_to_title? || will_save_change_to_body? || will_save_change_to_kind? || will_save_change_to_category_id? }

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :most_voted_first, -> { order(votes_count: :desc, created_at: :desc, id: :desc) }
  scope :on_roadmap, -> { where(status: ROADMAP_STATUSES) }

  # Hidden suggestions are visible only to their author and the admin.
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

  # Voting and commenting: signed in, not blocked, suggestion not hidden.
  def open_for_participation_by?(user)
    user.present? && user.can_participate? && !hidden?
  end

  # Edit/delete by the author: not blocked and not hidden by a moderator.
  def editable_by?(user)
    authored_by?(user) && user.can_participate? && !hidden?
  end

  def deletable_by?(user)
    return false unless user
    user.admin? || editable_by?(user)
  end

  def voted_by?(user)
    return false unless user
    if votes.loaded?
      votes.any? { |v| v.user_id == user.id }
    else
      votes.exists?(user_id: user.id)
    end
  end

  def status_label = STATUSES.fetch(status)[:label]
  def status_css = STATUSES.fetch(status)[:css]
  def status_desc = STATUSES.fetch(status)[:desc]
  def kind_label = KINDS.fetch(kind)[:label]
  def kind_icon = KINDS.fetch(kind)[:icon]
  def category_name = category&.name || "Uncategorized"
  def on_roadmap? = ROADMAP_STATUSES.include?(status)
  def edited? = edited_at.present?

  def excerpt
    body.to_s.split(/\n{2,}/).first.to_s
  end

  def paragraphs
    body.to_s.split(/\n{2,}/)
  end

  private
    def mark_edited
      self.edited_at = Time.current
    end
end
