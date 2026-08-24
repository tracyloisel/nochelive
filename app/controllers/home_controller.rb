class HomeController < ApplicationController
  def index
    @nights = GameSession.live.includes(:players).order(updated_at: :desc).limit(8)
    @theme = GameDefinition.default.theme
    @memories = if current_ward
      current_ward.game_sessions.finished.includes(:teams, :players, :missionaries, :ward).order(updated_at: :desc).limit(6)
    else
      GameSession.none
    end
  end
end
