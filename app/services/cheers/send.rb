module Cheers
  class Send
    def self.call(night:, player:, to_player:)
      new(night:, player:, to_player:).call
    end

    def initialize(night:, player:, to_player:)
      @night = night
      @player = player
      @to_player = to_player
    end

    def call
      raise "Solo desde casa" unless @player.remote?
      raise "Solo jugadores" unless @player.participant?
      raise "No te animes" if @to_player.id == @player.id
      raise "Solo la sala" unless @to_player.participant? && !@to_player.remote?
      raise "Otra noche" unless @to_player.game_session_id == @night.id

      round = @night.current_round_run
      raise "No round" unless round&.definition&.layered_finale?
      raise "Capa cerrada" unless cheer_layer?(round)

      cheer = persist!(round)
      return cheer unless cheer.previously_new_record?

      @night.broadcast_state(pulse: {
        kind: "cheer",
        player: @player,
        to: @to_player,
        mark: "fire",
        label: I18n.t("presenter.cheer_line", from: @player.name, to: @to_player.name)
      })
      cheer
    end

    private

      def persist!(round)
        ApplicationRecord.transaction do
          locked = RoundRun.lock.find(round.id)
          raise "Capa cerrada" unless cheer_layer?(locked)

          existing = Cheer.find_by(round_run: locked, player: @player, layer_index: locked.layer_index)
          return existing if existing

          Cheer.create!(
            round_run: locked,
            player: @player,
            to_player: @to_player,
            layer_index: locked.layer_index,
            mark: "fire"
          )
        end
      end

      def cheer_layer?(round)
        max = round.definition.layers.size - 1
        round.intro? && round.layer_index.between?(1, max)
      end
  end
end
