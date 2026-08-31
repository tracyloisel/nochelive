class WardEventAudit < ApplicationRecord
  ACTIONS = %w[created updated published cancelled].freeze
  ACTOR_LABEL_MAX = 120

  belongs_to :ward_event
  belongs_to :ward

  validates :action, inclusion: { in: ACTIONS }
  validates :actor_label, presence: true, length: { maximum: ACTOR_LABEL_MAX }
  validates :metadata, presence: true
  validate :same_ward

  attr_readonly :ward_event_id, :ward_id, :action, :actor_label, :metadata, :created_at

  private

    def same_ward
      return if ward_event.blank? || ward.blank? || ward_event.ward_id == ward_id

      errors.add(:ward, :invalid)
    end
end
