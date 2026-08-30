class ScriptureTag < ApplicationRecord
  NAME_LIMIT = 40

  belongs_to :person
  has_many :scripture_mark_taggings, dependent: :destroy
  has_many :scripture_marks, through: :scripture_mark_taggings

  validates :name, :normalized_name, presence: true
  validates :name, length: { maximum: NAME_LIMIT }
  validates :normalized_name, uniqueness: { scope: :person_id }

  before_validation :normalize_name

  def self.normalize(value)
    I18n.transliterate(value.to_s.squish).downcase.gsub(/[^a-z0-9 -]/, "").squish
  end

  private

    def normalize_name
      self.name = name.to_s.squish
      self.normalized_name = self.class.normalize(name)
    end
end
