class User < ApplicationRecord
  EMAIL_FORMAT = /\A[^\s@]+@[^\s@]+\.[^\s@]{2,}\z/

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :suggestions, foreign_key: :author_id, inverse_of: :author, dependent: :destroy
  has_many :comments, foreign_key: :author_id, inverse_of: :author, dependent: :destroy
  has_many :votes, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.squish }

  validates :name, presence: { message: "Enter your name." }, length: { maximum: 50, message: "Use 50 characters or fewer." }
  validates :email_address, presence: { message: "Enter your email address." }
  validates :email_address, format: { with: EMAIL_FORMAT, message: "Enter an email address like name@example.com." }, allow_blank: true
  validates :email_address, uniqueness: { message: "An account with this email already exists. Sign in instead." }, allow_blank: true
  validates :password, length: { minimum: 8, message: "Use at least 8 characters for your password." }, allow_nil: true
  validates :admin, uniqueness: { message: "There can be only one admin." }, if: :admin?

  scope :by_name, -> { order(Arel.sql("lower(name)")) }

  # Blocked users can sign in and browse but cannot create, vote, comment or edit.
  def can_participate?
    !blocked?
  end

  def block!
    raise ArgumentError, "The admin can't be blocked" if admin?
    update!(blocked: true)
  end

  def unblock!
    update!(blocked: false)
  end

  def initials
    name.split(/\s+/).filter_map { |part| part[0] }.first(2).join.upcase
  end

  # Decorative avatar color, stable per user.
  def avatar_hue
    (self[:avatar_hue] || id.to_i) % 6
  end

  def first_name
    name.split(/\s+/).first
  end
end
