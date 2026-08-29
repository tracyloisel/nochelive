require "digest"

class DuelInvitation < ApplicationRecord
  STATUSES = %w[open claimed declined expired revoked].freeze
  TOKEN_PURPOSE = :duel_invitation

  belongs_to :challenger_person, class_name: "Person"
  belongs_to :recipient_person, class_name: "Person", optional: true
  belongs_to :challenger_run, class_name: "QuizRun", optional: true
  belongs_to :claimed_by_person, class_name: "Person", optional: true
  belongs_to :street_duel, optional: true, inverse_of: :duel_invitations
  belongs_to :rematch_of_duel, class_name: "StreetDuel", optional: true
  belongs_to :acquisition_parent_invitation, class_name: "DuelInvitation", optional: true
  has_many :acquired_invitations,
    class_name: "DuelInvitation",
    foreign_key: :acquisition_parent_invitation_id,
    dependent: :nullify,
    inverse_of: :acquisition_parent_invitation
  has_many :viral_events, dependent: :nullify

  validates :token_digest, :status, :expires_at, presence: true
  validates :token_digest, uniqueness: true
  validates :legacy_token_digest, uniqueness: true, allow_nil: true
  validates :status, inclusion: { in: STATUSES }
  validates :source, :channel, length: { maximum: 40 }, allow_blank: true
  validate :people_are_distinct

  scope :open_state, -> { where(status: "open") }
  scope :not_expired, -> { where("expires_at > ?", Time.current) }
  scope :incoming_for, ->(person) { where(recipient_person: person) }
  scope :outgoing_for, ->(person) { where(challenger_person: person) }

  STATUSES.each { |value| define_method("#{value}?") { status == value } }

  def self.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  def self.find_by_token(token)
    value = token.to_s
    return if value.blank?

    digest = digest(value)
    find_by(token_digest: digest) || find_by(legacy_token_digest: digest) || begin
      invitation = find_signed(value, purpose: TOKEN_PURPOSE)
      invitation if invitation && ActiveSupport::SecurityUtils.secure_compare(invitation.token_digest, digest)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end
  end

  def refresh_public_token!
    token = signed_id(purpose: TOKEN_PURPOSE)
    digest = self.class.digest(token)
    update_column(:token_digest, digest) unless ActiveSupport::SecurityUtils.secure_compare(token_digest, digest)
    token
  end

  def public_token
    refresh_public_token!
  end

  def available?
    open? && !expired?
  end

  def expired?
    status == "expired" || expires_at <= Time.current
  end

  def external? = recipient_person_id.nil?
  def named? = recipient_person_id.present?
  def rematch? = rematch_of_duel_id.present?

  def receipt_state
    return :claimed if claimed? || claimed_at.present?
    return :declined if declined?
    return :seen if seen_at.present?
    return :opened if external? && human_opened_at.present?
    return :delivered if delivered_at.present?

    :sent
  end

  private

    def people_are_distinct
      return if recipient_person_id.blank? || recipient_person_id != challenger_person_id

      errors.add(:recipient_person, :invalid)
    end
end
