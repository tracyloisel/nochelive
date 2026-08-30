class ScriptureMark < ApplicationRecord
  attr_accessor :pending_related_annotation
  SELECTED_TEXT_LIMIT = 10_000
  NOTE_BODY_LIMIT = 5_000
  ANCHOR_SCOPES = %w[chapter passage].freeze
  VISUAL_STYLES = %w[none highlight underline].freeze
  COLOR_KEYS = %w[gold clay sage rose].freeze
  INTENT_KEYS = %w[promise question gratitude action reread].freeze

  belongs_to :person
  has_many :scripture_mark_taggings, dependent: :destroy
  has_many :scripture_tags, through: :scripture_mark_taggings
  has_many :scripture_notebook_entries, dependent: :destroy
  has_many :scripture_notebooks, through: :scripture_notebook_entries
  has_many :scripture_mark_links, dependent: :destroy

  validates :reference, :locale, :anchor_scope, :visual_style, presence: true
  validates :locale, inclusion: { in: Locale::AVAILABLE }
  validates :anchor_scope, inclusion: { in: ANCHOR_SCOPES }
  validates :visual_style, inclusion: { in: VISUAL_STYLES }
  validates :color_key, inclusion: { in: COLOR_KEYS }, allow_nil: true
  validates :intent_key, inclusion: { in: INTENT_KEYS }, allow_nil: true
  validates :selected_text, length: { maximum: SELECTED_TEXT_LIMIT }, allow_blank: true
  validates :note_body, length: { maximum: NOTE_BODY_LIMIT }, allow_blank: true
  validate :known_reference
  validate :valid_anchor
  validate :useful_annotation

  before_validation :normalize_text

  scope :active, -> { where(discarded_at: nil) }
  scope :for_reader, ->(reference:, locale:) { active.where(reference:, locale: locale.to_s).order(:created_at, :id) }

  def reader_attributes
    attributes.symbolize_keys.slice(
      :id, :anchor_scope, :start_verse, :end_verse, :start_offset, :end_offset,
      :selected_text, :visual_style, :color_key, :bookmarked_at, :intent_key, :note_body
    ).merge(
      delete_url: Rails.application.routes.url_helpers.scripture_mark_path(self),
      update_url: Rails.application.routes.url_helpers.scripture_mark_path(self),
      restore_url: Rails.application.routes.url_helpers.restore_scripture_mark_path(self),
      tags: scripture_tags.map(&:name),
      notebooks: scripture_notebooks.map { |notebook| { id: notebook.id, title: notebook.title } },
      links: scripture_mark_links.map do |link|
        { id: link.id, reference: link.target_reference, locale: link.target_locale, text: link.target_text }
      end
    )
  end

  def chapter_anchor? = anchor_scope == "chapter"
  def passage_anchor? = anchor_scope == "passage"

  private

    def normalize_text
      self.selected_text = selected_text.to_s.squish.presence
      self.note_body = note_body.to_s.strip.presence
      self.color_key = nil if visual_style == "none"
    end

    def known_reference
      errors.add(:reference, :invalid) unless Scriptures::Reference.known_study?(reference)
    end

    def valid_anchor
      if chapter_anchor?
        errors.add(:base, :invalid) if [ start_verse, start_offset, end_verse, end_offset ].any?(&:present?)
        return
      end

      values = [ start_verse, start_offset, end_verse, end_offset ]
      return errors.add(:base, :invalid) if values.any?(&:nil?)
      return errors.add(:end_verse, :invalid) if end_verse < start_verse
      return if end_verse > start_verse || end_offset > start_offset

      errors.add(:end_offset, :greater_than, count: start_offset)
    end

    def useful_annotation
      useful = visual_style != "none" || bookmarked_at.present? || note_body.present? ||
        scripture_mark_taggings.any? || scripture_notebook_entries.any? || scripture_mark_links.any? || pending_related_annotation
      errors.add(:base, :blank) unless useful
    end
end
