class RewardGrant < ApplicationRecord
  CHESTS = {
    "cofre_salomon" => "Cofre de Salomón"
  }.freeze

  REWARDS = {
    "corona" => { title: "Corona del Rey", detail: "La próxima respuesta correcta vale el doble." },
    "fuego" => { title: "Fuego de Elías", detail: "+8 puntos de fuego inmediato." },
    "escudo" => { title: "Escudo de David", detail: "+5 puntos de protección." },
    "sabiduria" => { title: "Sabiduría", detail: "+6 puntos de sabiduría." }
  }.freeze

  belongs_to :team

  validates :chest_key, :state, presence: true
  validates :chest_key, inclusion: { in: CHESTS.keys }

  def ready? = state == "ready"
  def opened? = state == "opened"
  def chest_title
    I18n.t("rewards.chests.#{chest_key}", default: CHESTS[chest_key])
  end

  def reward_title
    I18n.t("rewards.#{reward_key}.title", default: REWARDS.dig(reward_key, :title)) if reward_key.present?
  end

  def reward_detail
    I18n.t("rewards.#{reward_key}.detail", default: REWARDS.dig(reward_key, :detail)) if reward_key.present?
  end

  def open!
    raise "Chest already opened" unless ready?

    ApplicationRecord.transaction do
      key = REWARDS.keys.sample
      update!(state: "opened", reward_key: key)
      apply_reward!(key)
    end
  end

  private

  def apply_reward!(key)
    case key
    when "corona"
      team.update!(next_correct_doubled: true)
    when "fuego"
      ScoreEvent.award!(game_session: team.game_session, team: team, kind: "chest", points: 8, xp: 8, reason: "scores.chest_fuego")
    when "escudo"
      ScoreEvent.award!(game_session: team.game_session, team: team, kind: "chest", points: 5, xp: 5, reason: "scores.chest_escudo")
    when "sabiduria"
      ScoreEvent.award!(game_session: team.game_session, team: team, kind: "chest", points: 6, xp: 6, reason: "scores.chest_sabiduria")
    end
  end
end
