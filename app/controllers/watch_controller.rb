class WatchController < ApplicationController
  before_action :set_night

  def show
    unless current_player
      player = @night.players.create!(
        name: I18n.t("watch.audience_name"),
        role: "spectator",
        client_token: SecureRandom.uuid,
        avatar_key: "oveja",
        locale: Locale.cast(locale_preference),
        last_seen_at: Time.current
      )
      remember_player(player)
    end
  end
end
