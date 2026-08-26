class StreetPackStartsController < ApplicationController
  include StreetQuiz

  def create
    remember_device
    Quizzes::StartPack.call(
      device_digest: street_digest,
      person_id: current_street_person&.id,
      pack_id: params[:pack_id]
    )
    redirect_to jugar_path
  rescue Quizzes::StartPack::Locked
    redirect_to root_path, alert: I18n.t("street.pack_locked")
  end
end
