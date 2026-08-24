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
    { 1 => "1.º", 2 => "2.º", 3 => "3.º" }[position] || "#{position}.º"
  end
end
