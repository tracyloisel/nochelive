class Buzz < ApplicationRecord
  self.table_name = "buzzes"
  belongs_to :round_run
  belongs_to :team
  belongs_to :player

  validates :position, presence: true, numericality: { greater_than: 0 }

  def self.accept!(round_run:, team:, player:)
    Buzzes::Accept.call(round_run:, team:, player:)
  end

  def first? = position == 1
  def medal
    I18n.t("ordinals.#{position}", default: I18n.t("ordinals.other", n: position))
  end
end
