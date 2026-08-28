module Nights
  class Start
    def self.call(ward:, theme_id: "reyes_y_profetas")
      new(ward:, theme_id:).call
    end

    def initialize(ward:, theme_id:)
      @ward = ward
      @theme_id = theme_id
    end

    def call
      definition = GameDefinition.load(@theme_id)
      token = SecureRandom.urlsafe_base64(24)
      night = allocate_night(definition, token)
      raise "Could not allocate a session code" unless night

      ApplicationRecord.transaction do
        definition.rounds.each_with_index do |round, index|
          night.round_runs.create!(yaml_round_id: round.id, position: index + 1, phase: "pending")
        end

        @ward.ward_teams.find_each do |ward_team|
          night.teams.create!(
            name: ward_team.name,
            emblem: ward_team.emblem,
            ward_team: ward_team
          )
        end
      end

      night
    end

    private

      def allocate_night(definition, token)
        night = nil
        8.times do
          GameSession.transaction(requires_new: true) do
            night = GameSession.create!(
              ward: @ward,
              code: GameSession.generate_code,
              status: "lobby",
              theme_id: definition.theme.id,
              theme_title: definition.theme.title,
              starts_at: Time.current,
              presenter_locale: Locale.cast(I18n.locale),
              presenter_token_digest: GameSession.digest_token(token)
            )
          end
          night.presenter_token = token
          break
        rescue ActiveRecord::RecordNotUnique
          night = nil
        end
        night
      end
  end
end
