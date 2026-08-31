require "digest"
require "set"

class ScriptureCirclePost < ApplicationRecord
  MAX_BODY_LENGTH = 500
  SELECTED_TEXT_LIMIT = 1_000
  SELECTED_VERSES_LIMIT = 120
  SELECTED_VERSE_COUNT_LIMIT = 176
  KINDS = %w[reflection question reply].freeze
  STATUSES = %w[visible vote_open community_censored author_deleted].freeze
  AUTHOR_VISIBILITIES = %w[named anonymous_to_ward].freeze
  URL_PATTERN = %r{(?:https?://|www\.|\b[A-Za-z0-9.-]+\.(?:com|org|net|io|fr|es|pt|br)\b)}i
  HTML_PATTERN = /<[^>]+>/
  SHOWCASE_SELECTED_TEXT_PATTERN = /\Ascripture-(?:circle-showcase|reader-demo)-v\d+:/

  belongs_to :scripture_circle_thread
  belongs_to :ward
  belongs_to :person, optional: true
  belongs_to :parent, class_name: "ScriptureCirclePost", optional: true
  belongs_to :conversation_root, class_name: "ScriptureCirclePost", optional: true
  has_many :replies, class_name: "ScriptureCirclePost", foreign_key: :parent_id, dependent: :nullify,
    inverse_of: :parent
  has_many :conversation_posts, class_name: "ScriptureCirclePost", foreign_key: :conversation_root_id,
    inverse_of: :conversation_root
  has_many :scripture_circle_conversation_votes, foreign_key: :conversation_root_id, dependent: :destroy,
    inverse_of: :conversation_root
  has_many :scripture_circle_post_votes, dependent: :destroy, inverse_of: :scripture_circle_post
  has_many :scripture_circle_post_revisions, dependent: :destroy
  has_many :scripture_circle_moderation_reports, dependent: :destroy
  has_many :scripture_circle_moderation_proposals, dependent: :destroy

  validates :kind, :locale, :body, :status, presence: true
  validates :body, length: { maximum: MAX_BODY_LENGTH }
  validates :selected_text, length: { maximum: SELECTED_TEXT_LIMIT }, allow_blank: true
  validates :selected_verses, length: { maximum: SELECTED_VERSES_LIMIT }, allow_blank: true
  validates :anonymous, inclusion: { in: [ true, false ] }
  validates :author_visibility, inclusion: { in: AUTHOR_VISIBILITIES }
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :locale, inclusion: { in: Locale::AVAILABLE }
  validate :plain_short_body
  validate :thread_and_ward_match
  validate :author_belongs_to_ward_on_create
  validate :valid_parent
  validate :valid_conversation_root
  validate :anonymous_visibility_is_question_root
  validate :valid_verse_range
  validate :valid_selected_verses

  before_validation :normalize_content
  before_validation :normalize_author_visibility
  before_validation :inherit_conversation_root_from_parent
  after_create :assign_self_as_conversation_root
  after_create :append_created_revision
  after_update :append_changed_revision

  scope :chronological, -> { order(:created_at, :id) }
  scope :renderable, -> { where(status: STATUSES) }
  scope :visible, -> { where(status: "visible") }
  scope :roots, -> { where(parent_id: nil) }

  def public_body
    body if status.in?(%w[visible])
  end

  # Demo fixtures use selected_text as a stable internal marker. It is not a
  # passage and must never be presented as one to people reading the Circle.
  def selected_text_for_display
    selected_text unless selected_text.to_s.match?(SHOWCASE_SELECTED_TEXT_PATTERN)
  end

  def root? = parent_id.nil?
  def question_root? = root? && kind == "question"
  def conversation_root? = root? && conversation_root_id == id
  def named? = author_visibility == "named"
  def anonymous_to_ward? = author_visibility == "anonymous_to_ward"

  # The boolean remains only for older forms and historical rows. All new
  # display and selection decisions use author_visibility.
  def anonymous? = anonymous_to_ward?

  def conversation_vote_score
    read_attribute(:circle_vote_score).to_i
  end

  def conversation_vote_for(person)
    return unless person

    votes = scripture_circle_conversation_votes
    return votes.find { |vote| vote.voter_person_id == person.id } if association(:scripture_circle_conversation_votes).loaded?

    votes.find_by(voter_person_id: person.id)
  end

  def post_vote_score
    votes = scripture_circle_post_votes
    return votes.sum(&:score) if association(:scripture_circle_post_votes).loaded?

    votes.sum("CASE direction WHEN 'up' THEN 1 WHEN 'down' THEN -1 ELSE 0 END")
  end

  def post_vote_for(person)
    return unless person

    votes = scripture_circle_post_votes
    return votes.find { |vote| vote.voter_person_id == person.id } if association(:scripture_circle_post_votes).loaded?

    votes.find_by(voter_person_id: person.id)
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
    return self if conversation_root_id.blank? || conversation_root_id == id
    return conversation_root if association(:conversation_root).loaded?
    return conversation_root if conversation_root

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
      anonymous: anonymous_to_ward?,
      author_visibility:,
      change_kind:,
      content_digest: Digest::SHA256.hexdigest([ body, start_verse, end_verse, author_visibility, number ].join("\u0000"))
    )
  end

  private

    def normalize_content
      self.body = body.to_s.strip
      self.selected_text = selected_text.to_s.squish.presence
      parsed_selected_verses = parse_selected_verses(selected_verses)
      self.selected_verses = format_selected_verses(parsed_selected_verses) if parsed_selected_verses
      self.selected_verses = nil if selected_verses.blank?
    end

    def normalize_author_visibility
      self.author_visibility = author_visibility.to_s.presence || "named"
      self[:anonymous] = anonymous_to_ward?
    end

    def inherit_conversation_root_from_parent
      return unless parent

      self.conversation_root_id ||= parent.conversation_root_id || parent.root_post.id
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
        errors.add(:parent, :invalid) unless parent.status == "visible"
      elsif parent.present?
        errors.add(:parent, :invalid)
      end
      errors.add(:parent, :invalid) if parent_id.present? && parent_id == id
    end

    def valid_conversation_root
      if root?
        return if new_record? && conversation_root_id.blank?
        return if conversation_root_id == id

        errors.add(:conversation_root, :invalid)
        return
      end

      return if parent.blank?
      root = conversation_root
      valid = root&.root? && root.status == "visible" && root.id == conversation_root_id &&
        root.ward_id == ward_id && root.scripture_circle_thread_id == scripture_circle_thread_id &&
        parent.conversation_root_id == root.id
      errors.add(:conversation_root, :invalid) unless valid
    end

    def anonymous_visibility_is_question_root
      return unless anonymous_to_ward?
      return if question_root?

      errors.add(:author_visibility, :invalid)
    end

    def assign_self_as_conversation_root
      return if conversation_root_id.present?

      self.conversation_root_id = id
      update_column(:conversation_root_id, id)
    end

    def valid_verse_range
      return if start_verse.blank? && end_verse.blank?
      return errors.add(:start_verse, :invalid) unless start_verse.to_i.positive?
      errors.add(:end_verse, :invalid) unless end_verse.to_i >= start_verse.to_i
    end

    def valid_selected_verses
      return if selected_verses.blank?

      verses = parse_selected_verses(selected_verses)
      valid = verses.present? && selected_text.present? && start_verse.to_i == verses.first && end_verse.to_i == verses.last
      errors.add(:selected_verses, :invalid) unless valid
    end

    def parse_selected_verses(value)
      normalized = value.to_s.tr("–—", "--").gsub(/\s+/, "")
      return [] if normalized.blank?

      ranges = normalized.split(",").map do |segment|
        from, to = segment.split("-", 2)
        return unless from&.match?(/\A\d+\z/) && (to.nil? || to.match?(/\A\d+\z/))

        first = from.to_i
        last = (to || from).to_i
        return unless first.positive? && last >= first && (last - first + 1) <= SELECTED_VERSE_COUNT_LIMIT

        (first..last).to_a
      end
      verses = ranges.flatten.uniq.sort
      return if verses.length > SELECTED_VERSE_COUNT_LIMIT

      verses
    end

    def format_selected_verses(verses)
      verses.slice_when { |previous, current| current != previous + 1 }.map do |group|
        group.one? ? group.first.to_s : "#{group.first}-#{group.last}"
      end.join(", ")
    end

    def append_created_revision
      append_revision!(change_kind: "created")
    end

    def append_changed_revision
      if saved_change_to_body?
        append_revision!(change_kind: "edited")
      elsif saved_change_to_author_visibility?
        append_revision!(change_kind: "anonymity_changed")
      elsif saved_change_to_status? && status == "author_deleted"
        append_revision!(change_kind: "author_deleted")
      end
    end
end
