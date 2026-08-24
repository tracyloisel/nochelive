class WatchController < ApplicationController
  before_action :set_night

  def show
    unless current_player
      player = @night.players.create!(
        name: "Público",
        role: "spectator",
        client_token: SecureRandom.uuid,
        avatar_key: "oveja",
        last_seen_at: Time.current
      )
      remember_player(player)
    end
  end
end
