class ViralEvent < ApplicationRecord
  NAMES = %w[
    invite_prompt_seen
    duel_invitation_created
    invite_share_opened
    invite_share_handoff
    invite_link_rendered
    invite_human_opened
    invite_claimed
    invite_declined
    invitee_profile_created
    first_question_started
    duel_result_viewed
    invitee_first_outbound_invite
    pair_returned_d7
    named_invite_delivered
    named_invite_seen
    duel_activated
    duel_run_committed
    duel_resolved
    duel_campus_viewed
    duel_rematch_started
    multi_duel_run_completed
  ].freeze

  belongs_to :street_duel, optional: true
  belongs_to :duel_invitation, optional: true
  belongs_to :person, optional: true

  validates :device_digest, :name, presence: true
  validates :name, inclusion: { in: NAMES }
  validates :source, length: { maximum: 40 }, allow_blank: true
  validates :event_key, uniqueness: true, allow_blank: true

  scope :funnel, -> { order(:created_at) }
end
