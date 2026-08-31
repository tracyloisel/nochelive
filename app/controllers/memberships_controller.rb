class MembershipsController < ApplicationController
  before_action :set_night, :require_player

  def create
    @night.reconcile!
    raise People::Error.new(:team, I18n.t("nights.team_selection_closed")) unless @night.open_for_team_selection?
    team = @night.teams.find(params[:team_id])
    Memberships::Join.call(night: @night, player: current_player, team:)
    redirect_to(@night.playable? ? night_play_path(@night.code) : night_path(@night.code))
  rescue People::Error => error
    redirect_to night_path(@night.code), alert: error.message
  end
end
