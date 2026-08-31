class WardEvent < ApplicationRecord
  class TransitionError < StandardError; end

  KINDS = %w[
    clothing_drive
    toy_drive
    books_and_school_supplies_drive
    food_drive
    sports_activity
    music_activity
    art_activity
  ].freeze
  STATUSES = %w[draft published cancelled].freeze
  EDITABLE_ATTRIBUTES = %i[
    kind title summary starts_at ends_at location_label
    destination_path destination_url artwork_path
  ].freeze
  SAFE_INTERNAL_DESTINATIONS = {
    "ward_profiles" => %w[show],
    "street_leaderboards" => %w[show],
    "players" => %w[new],
    "play" => %w[show]
  }.freeze
  INTERNAL_DESTINATION = %r{\A/(?!/)[^\\\r\n]*\z}
  ARTWORK_PATH = %r{\A/media/[a-z0-9][a-z0-9_./-]*\.(?:jpe?g|png|webp)\z}i

  belongs_to :ward
  has_many :ward_event_audits, dependent: :destroy, inverse_of: :ward_event

  validates :kind, :title, :summary, :starts_at, :ends_at, :location_label, :status, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :title, length: { maximum: 120 }
  validates :summary, length: { maximum: 280 }
  validates :location_label, length: { maximum: 120 }
  validates :approved_by, :cancelled_by, length: { maximum: WardEventAudit::ACTOR_LABEL_MAX }, allow_blank: true
  validates :cancellation_reason, length: { maximum: 280 }, allow_blank: true
  validates :destination_path, format: { with: INTERNAL_DESTINATION }, allow_blank: true
  validates :artwork_path, format: { with: ARTWORK_PATH }, allow_blank: true
  validates :approved_by, :approved_at, presence: true, if: :published?
  validates :cancelled_by, :cancelled_at, :cancellation_reason, presence: true, if: :cancelled?
  validate :ends_after_starts
  validate :one_destination
  validate :valid_internal_destination
  validate :valid_external_destination
  validate :known_artwork

  scope :with_audit, ->(action) {
    audit = WardEventAudit.where("ward_event_audits.ward_event_id = ward_events.id").where(action:)
    where(audit.arel.exists)
  }
  scope :published, lambda {
    where(status: "published")
      .where.not(approved_by: nil)
      .where.not(approved_at: nil)
      .with_audit("published")
  }
  scope :visible_at, ->(at = Time.current) { published.where("ends_at > ?", at) }
  scope :cancelled_for_hub, lambda {
    where(status: "cancelled")
      .where.not(approved_by: nil)
      .where.not(approved_at: nil)
      .where.not(cancelled_by: nil)
      .where.not(cancelled_at: nil)
      .where.not(cancellation_reason: nil)
      .with_audit("published")
      .with_audit("cancelled")
  }
  scope :visible_or_cancelled_at, ->(at = Time.current) {
    visible_at(at).or(cancelled_for_hub.where("ends_at > ?", at))
  }
  scope :chronological, -> { order(:starts_at, :id) }

  STATUSES.each { |value| define_method("#{value}?") { status == value } }

  def self.create_draft!(ward:, attributes:, actor:, at: Time.current)
    transaction do
      event = ward.ward_events.create!(editable_attributes(attributes).merge(status: "draft"))
      event.record_audit!("created", actor:, at:, metadata: { "status" => event.status })
      event
    end
  end

  def update_draft!(attributes:, actor:, at: Time.current)
    with_lock do
      raise TransitionError, "Only drafts can be edited" unless draft?

      assign_attributes(attributes.to_h.symbolize_keys.slice(*EDITABLE_ATTRIBUTES))
      save!
      record_audit!("updated", actor:, at:, metadata: { "changed" => previous_changes.keys.sort })
    end
    self
  end

  def publish!(actor:, at: Time.current)
    with_lock do
      raise TransitionError, "Only drafts can be published" unless draft?

      actor_label = normalized_actor!(actor)
      update!(status: "published", approved_by: actor_label, approved_at: at)
      record_audit!("published", actor: actor_label, at:, metadata: { "status" => status })
    end
    self
  end

  def cancel!(actor:, reason:, at: Time.current)
    with_lock do
      raise TransitionError, "Only published events can be cancelled" unless published?

      actor_label = normalized_actor!(actor)
      update!(
        status: "cancelled",
        cancelled_by: actor_label,
        cancelled_at: at,
        cancellation_reason: reason.to_s.squish
      )
      record_audit!("cancelled", actor: actor_label, at:, metadata: { "reason" => cancellation_reason })
    end
    self
  end

  def destination
    destination_path.presence || destination_url
  end

  def external_destination? = destination_url.present?

  def record_audit!(action, actor:, at:, metadata: {})
    ward_event_audits.create!(
      ward:,
      action:,
      actor_label: normalized_actor!(actor),
      metadata:,
      created_at: at
    )
  end

  private

    class << self
      private

        def editable_attributes(attributes)
          attributes.to_h.symbolize_keys.slice(*EDITABLE_ATTRIBUTES)
        end
    end

    def normalized_actor!(actor)
      value = actor.to_s.squish
      raise ArgumentError, "actor is required" if value.blank?
      raise ArgumentError, "actor is too long" if value.length > WardEventAudit::ACTOR_LABEL_MAX

      value
    end

    def ends_after_starts
      return if starts_at.blank? || ends_at.blank? || ends_at >= starts_at

      errors.add(:ends_at, :before_start)
    end

    def one_destination
      return if destination_path.present? ^ destination_url.present?

      errors.add(:base, "requires exactly one destination")
    end

    def valid_external_destination
      return if destination_url.blank?

      uri = URI.parse(destination_url)
      return if uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.blank?

      errors.add(:destination_url, :invalid)
    rescue URI::InvalidURIError
      errors.add(:destination_url, :invalid)
    end

    def valid_internal_destination
      return if destination_path.blank?

      uri = URI.parse(destination_path)
      return errors.add(:destination_path, :invalid) unless uri.scheme.blank? && uri.host.blank? && uri.userinfo.blank?

      route = Rails.application.routes.recognize_path(uri.path, method: :get)
      return if safe_internal_route?(route)

      errors.add(:destination_path, :invalid)
    rescue URI::InvalidURIError, ActionController::RoutingError
      errors.add(:destination_path, :invalid)
    end

    def safe_internal_route?(route)
      SAFE_INTERNAL_DESTINATIONS.fetch(route[:controller].to_s, []).include?(route[:action].to_s) && route_target_exists?(route)
    end

    def route_target_exists?(route)
      case route[:controller]
      when "players", "play"
        GameSession.find_by_code(route[:session_code]).present?
      when "ward_profiles", "street_leaderboards"
        Ward.exists?(code: Ward.normalize_code(route[:code]))
      else
        false
      end
    end

    def known_artwork
      return if artwork_path.blank?

      relative_path = artwork_path.delete_prefix("/")
      return if Frontend::MediaManifest.fetch_source(relative_path)
      return if Rails.public_path.join(relative_path).file?

      errors.add(:artwork_path, :invalid)
    end
end
