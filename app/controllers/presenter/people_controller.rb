module Presenter
  class PeopleController < ApplicationController
    before_action :set_night, :require_presenter

    def create
      player = @night.players.find(params[:player_id])
      person = resolve_person
      People::LinkDevice.call(night: @night, player:, person:)
      @night.broadcast_state
      redirect_to presenter_console_path(@night.code)
    rescue People::Error => error
      redirect_to presenter_console_path(@night.code), alert: error.message
    end

    private

      def resolve_person
        person_id = params[:person_id].presence || params[:id]
        if person_id.present?
          @night.ward.people.find(person_id)
        elsif params[:given_name].present?
          cards = People::Recognize.call(ward: @night.ward, given_name: params[:given_name])
          raise People::Error.new(:person, I18n.t("errors.people.missing")) if cards.empty?
          raise People::Error.new(:person, I18n.t("errors.people.homonym")) if cards.many?

          cards.first.person
        else
          raise People::Error.new(:person, I18n.t("errors.people.missing"))
        end
      end
  end
end
