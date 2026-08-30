require "digest"
require "set"

class ScriptureCirclePost < ApplicationRecord
  MAX_BODY_LENGTH = 500
  SELECTED_TEXT_LIMIT = 1_000
  KINDS = %w[reflection question reply].freeze
  STATUSES = %w[visible vote_open community_censored author_deleted].freeze
  URL_PATTERN = %r{(?:https?://|www\.|\b[A-Za-z0-9.-]+\.(?:com|org|net|io|fr|es|pt|br)\b)}i
  HTML_PATTERN = /<[^>]+>/

  belongs_to :scripture_circle_thread
  belongs_to :ward
  belongs_to :person, optional: true
  belongs_to :parent, class_name: "ScriptureCirclePost", optional: true
  has_many :replies, class_name: "ScriptureCirclePost", foreign_key: :parent_id, dependent: :nullify,
    inverse_of: :parent
  has_many :scripture_circle_post_revisions, dependent: :destroy
  has_many :scripture_circle_moderation_proposals, dependent: :destroy

  validates :kind, :locale, :body, :status, presence: true
  validates :body, length: { maximum: MAX_BODY_LENGTH }
  validates :selected_text, length: { maximum: SELECTED_TEXT_LIMIT }, allow_blank: true
  validates :anonymous, inclusion: { in: [ true, false ] }
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :locale, inclusion: { in: Locale::AVAILABLE }
  validate :plain_short_body
  validate :thread_and_ward_match
  validate :author_belongs_to_ward_on_create
  validate :valid_parent
  validate :valid_verse_range

  before_validation :normalize_content
  after_create :append_created_revision
  after_update :append_changed_revision

  scope :chronological, -> { order(:created_at, :id) }
  scope :renderable, -> { where(status: STATUSES) }

  def public_body
    body if status.in?(%w[visible])
  end

  def author_name_for(viewer)
    return I18n.t("scripture_reader.circle.you") if viewer&.id == person_id
    return I18n.t("scripture_reader.circle.anonymous") if anonymous?
    return person.display_name if person&.ward_id == ward_id

    I18n.t("scripture_reader.circle.former_member")
  end

  def author_name
    author_name_for(nil)
  end

  def root_post
    current = self
    seen = Set.new
    while current.parent && seen.add?(current.id)
      current = current.parent
    end
    current
  end

  def latest_revision
    scripture_circle_post_revisions.order(revision_number: :desc).first
  end

  def append_revision!(change_kind:, editor_person: person)
    number = scripture_circle_post_revisions.maximum(:revision_number).to_i + 1
    scripture_circle_post_revisions.create!(
      editor_person:,
      ward:,
      revision_number: number,
      body:,
      start_verse:,
      end_verse:,
      anonymous:,
      change_kind:,
      content_digest: Digest::SHA256.hexdigest([ body, start_verse, end_verse, anonymous, number ].join("\u0000"))
    )
  end

  private

    def normalize_content
      self.body = body.to_s.strip
      self.selected_text = selected_text.to_s.squish.presence
    end

    def plain_short_body
      errors.add(:body, :invalid) if body.match?(URL_PATTERN) || body.match?(HTML_PATTERN)
      errors.add(:body, :blank) if body.gsub(/[\s\p{Cf}\p{Cc}]/, "").blank?
    end

    def thread_and_ward_match
      return if scripture_circle_thread.blank? || ward.blank?
      errors.add(:ward, :invalid) unless scripture_circle_thread.ward_id == ward_id
    end

    def author_belongs_to_ward_on_create
      return unless new_record?
      errors.add(:person, :blank) if person.blank?
      errors.add(:person, :invalid) if person && person.ward_id != ward_id
    end

    def valid_parent
      if kind == "reply"
        return errors.add(:parent, :blank) if parent.blank?
        errors.add(:parent, :invalid) unless parent.scripture_circle_thread_id == scripture_circle_thread_id && parent.ward_id == ward_id
      elsif parent.present?
        errors.add(:parent, :invalid)
      end
      errors.add(:parent, :invalid) if parent_id.present? && parent_id == id
    end

    def valid_verse_range
      return if start_verse.blank? && end_verse.blank?
      return errors.add(:start_verse, :invalid) unless start_verse.to_i.positive?
      return errors.add(:end_verse, :invalid) unless end_verse.to_i >= start_verse.to_i
    end

    def append_created_revision
      append_revision!(change_kind: "created")
    end

    def append_changed_revision
      if saved_change_to_body?
        append_revision!(change_kind: "edited")
      elsif saved_change_to_anonymous?
        append_revision!(change_kind: "anonymity_changed")
      elsif saved_change_to_status? && status == "author_deleted"
        append_revision!(change_kind: "author_deleted")
      end
    end
end
