class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :suggestion, counter_cache: true

  validates :user_id, uniqueness: { scope: :suggestion_id }
end
