class ViralEvent < ApplicationRecord
  NAMES = %w[
    invite_prompt_seen
    invite_share_opened
    invite_share_completed
    invite_link_opened
    challenge_started
    challenge_completed
    invitee_registered
    rematch_started
    pair_returned_d7
  ].freeze

  belongs_to :street_duel, optional: true
  belongs_to :person, optional: true

  validates :device_digest, :name, presence: true
  validates :name, inclusion: { in: NAMES }
  validates :source, length: { maximum: 40 }, allow_blank: true

  scope :funnel, -> { order(:created_at) }
end
