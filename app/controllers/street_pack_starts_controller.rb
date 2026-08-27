class StreetPackStartsController < ApplicationController
  include StreetQuiz

  def create
    remember_device
    unless current_street_person
      session[:pending_street_pack_id] = params[:pack_id]
      redirect_to street_profile_path(quick: 1, fresh: 1), notice: I18n.t("flashes.street_name_to_save")
      return
    end

    if current_street_person.ward && current_ward&.id != current_street_person.ward_id
      remember_ward(current_street_person.ward)
    end

    frame = Quizzes::StartPack.call(
      device_digest: street_digest,
      person_id: current_street_person&.id,
      pack_id: params[:pack_id]
    )
    session[:street_play_run_id] = frame.run.id
    redirect_to jugar_path
  rescue Quizzes::StartPack::Locked
    redirect_to root_path, alert: I18n.t("street.pack_locked")
  end
end
