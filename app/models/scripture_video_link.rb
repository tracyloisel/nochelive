class ScriptureVideoLink < ApplicationRecord
  STATUSES = %w[draft review published retired].freeze
  VIDEO_ID = /\A[A-Za-z0-9_-]{11}\z/
  CHANNEL_ID = /\AUC[A-Za-z0-9_-]{20,}\z/

  validates :reference, :locale, :youtube_video_id, :channel_id, :editorial_reason, :status, presence: true
  validates :reference, uniqueness: { scope: [ :locale, :youtube_video_id ] }
  validates :locale, inclusion: { in: Locale::AVAILABLE }
  validates :status, inclusion: { in: STATUSES }
  validates :youtube_video_id, format: { with: VIDEO_ID }
  validates :channel_id, format: { with: CHANNEL_ID }
  validates :editorial_reason, length: { maximum: 280 }
  validates :reviewed_by, :source_url, :published_at, presence: true, if: :published?
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :known_reference
  validate :official_channel
  validate :published_is_verified

  scope :published, -> { where(status: "published").where.not(verified_at: nil).where.not(published_at: nil).order(:position, :id) }

  def published? = status == "published"

  private

    def known_reference
      errors.add(:reference, :invalid) unless Scriptures::Reference.known_study?(reference)
    end

    def official_channel
      errors.add(:channel_id, :invalid) unless ChurchVideos::Catalog.official_channel_id?(locale:, channel_id:)
    end

    def published_is_verified
      errors.add(:verified_at, :blank) if published? && verified_at.blank?
    end
end
