class NightsController < ApplicationController
  before_action :set_night

  def show
    @night.reconcile!
    @night.reload
    @player = current_player
    if @night.phase.in?(%i[scheduled lobby])
      @projection = Nights::Projection.registration(night: @night)
      @reading_list = Nights::ReadingList.call(night: @night, locale: I18n.locale)
      @registered_players = @night.players.includes(:team).order(:name).limit(40)
    else
      @projection = Nights::Projection.call(night: @night)
      @reading_list = []
      @registered_players = []
    end
  end
end
