class StreetPackStartsController < ApplicationController
  include StreetQuiz

  def create
    remember_device
    expedition = expedition_for_pack
    unless current_street_person
      session[:pending_street_pack_id] = params[:pack_id]
      session[:pending_street_expedition_id] = expedition&.study_unit_id
      redirect_to street_profile_path(quick: 1, fresh: 1), notice: I18n.t("flashes.street_name_to_save")
      return
    end

    if current_street_person.ward && current_ward&.id != current_street_person.ward_id
      remember_ward(current_street_person.ward)
    end

    frame = Quizzes::StartPack.call(
      device_digest: street_digest,
      person_id: current_street_person&.id,
      pack_id: params[:pack_id],
      unlocked_pack_ids: expedition&.pack_ids
    )
    session[:street_expedition_id] = expedition&.study_unit_id
    session[:street_play_run_id] = frame.run.id
    redirect_to jugar_path
  rescue Quizzes::StartPack::Locked
    redirect_to root_path, alert: I18n.t("street.pack_locked")
  end

  private

    def expedition_for_pack
      return if params[:expedition].blank?

      expedition = Expeditions::Catalog.find(
        study_unit_id: params[:expedition],
        person: current_street_person,
        locale: I18n.locale
      )
      expedition if expedition&.includes_pack?(params[:pack_id])
    end
end
