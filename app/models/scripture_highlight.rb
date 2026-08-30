class ScriptureHighlight < ApplicationRecord
  SELECTED_TEXT_LIMIT = 10_000

  belongs_to :person

  validates :reference, :locale, presence: true
  validates :reference, uniqueness: {
    scope: [ :person_id, :locale, :start_verse, :end_verse, :start_offset, :end_offset ]
  }
  validates :locale, inclusion: { in: Locale::AVAILABLE }
  validates :start_verse, :end_verse,
    numericality: { only_integer: true, greater_than: 0 }
  validates :start_offset, :end_offset,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :selected_text, length: { maximum: SELECTED_TEXT_LIMIT }, allow_blank: true
  validate :known_reference
  validate :ordered_range

  before_validation :normalize_selected_text
  after_commit :mirror_to_scripture_mark, on: %i[create update]

  scope :for_reader, ->(reference:, locale:) { where(reference:, locale: locale.to_s).order(:created_at, :id) }

  def range_attributes
    attributes.symbolize_keys.slice(:start_verse, :end_verse, :start_offset, :end_offset)
  end

  def reader_attributes
    { id: }.merge(range_attributes)
  end

  private

    def normalize_selected_text
      self.selected_text = selected_text.to_s.squish.presence
    end

    def known_reference
      errors.add(:reference, :invalid) unless Scriptures::Reference.known_study?(reference)
    end

    def ordered_range
      return unless start_verse && end_verse && start_offset && end_offset
      return if end_verse > start_verse || end_offset > start_offset

      errors.add(:end_offset, :greater_than, count: start_offset)
    end

    def mirror_to_scripture_mark
      mark = person.scripture_marks.find_or_initialize_by(
        reference:, locale:, anchor_scope: "passage",
        start_verse:, start_offset:, end_verse:, end_offset:
      )
      mark.assign_attributes(selected_text:, visual_style: "highlight", color_key: "gold")
      mark.save!
    end
end
