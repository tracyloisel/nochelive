class StreetQuizHistoriesController < ApplicationController
  before_action :require_explicit_street_identity

  def show
    @history = StreetProfiles::AnswerHistory.call(
      person: @requested_street_person,
      page: params[:page],
      locale: I18n.locale
    )
  end
end
