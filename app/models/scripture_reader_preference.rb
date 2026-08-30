class ScriptureReaderPreference < ApplicationRecord
  FONT_SCALES = [ 90, 100, 115, 130, 145 ].freeze
  LINE_HEIGHT_KEYS = %w[compact comfortable ample].freeze
  MEASURE_KEYS = %w[focused comfortable wide].freeze
  FONT_FAMILY_KEYS = %w[editorial accessible].freeze
  BACKGROUND_KEYS = %w[paper soft contrast].freeze

  belongs_to :person

  validates :person_id, uniqueness: true
  validates :font_scale, inclusion: { in: FONT_SCALES }
  validates :line_height_key, inclusion: { in: LINE_HEIGHT_KEYS }
  validates :measure_key, inclusion: { in: MEASURE_KEYS }
  validates :font_family_key, inclusion: { in: FONT_FAMILY_KEYS }
  validates :background_key, inclusion: { in: BACKGROUND_KEYS }
  validates :illustrations_enabled, inclusion: { in: [ true, false ] }

  def reader_attributes
    attributes.slice(
      "font_scale", "line_height_key", "measure_key", "font_family_key",
      "background_key", "illustrations_enabled"
    )
  end
end
