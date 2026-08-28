class NotificationPreference < ApplicationRecord
  VERSE_FREQUENCIES = %w[daily three_weekly].freeze

  belongs_to :person

  validates :person_id, uniqueness: true
  validates :verse_frequency, inclusion: { in: VERSE_FREQUENCIES }
  validates :verse_local_time, :quiet_hours_start, :quiet_hours_end, presence: true

  def enabled_for?(kind)
    kind.to_s.start_with?("duel_") ? challenges_enabled? : verses_enabled?
  end

  def enable!(category)
    category = category.to_s
    case category
    when "challenges"
      update!(challenges_enabled: true, challenges_enabled_at: challenges_enabled_at || Time.current)
    when "verses"
      update!(verses_enabled: true, verses_enabled_at: verses_enabled_at || Time.current)
    else
      raise ArgumentError, "unknown notification category"
    end
  end

  def disable!(category)
    case category.to_s
    when "challenges" then update!(challenges_enabled: false)
    when "verses" then update!(verses_enabled: false)
    else raise ArgumentError, "unknown notification category"
    end
  end
end
