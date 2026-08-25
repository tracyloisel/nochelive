class Cheer < ApplicationRecord
  MARKS = %w[fire].freeze

  belongs_to :round_run
  belongs_to :player
  belongs_to :to_player, class_name: "Player"

  validates :layer_index, presence: true, numericality: { greater_than: 0 }
  validates :mark, presence: true, inclusion: { in: MARKS }
  validate :target_is_someone_else

  private

    def target_is_someone_else
      return if player_id.blank? || to_player_id.blank?
      return if player_id != to_player_id

      errors.add(:to_player, "cannot be yourself")
    end
end
