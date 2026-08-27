class StreetWardPicksController < ApplicationController
  def create
    ward = Wards::Enter.call(code: params[:code], church_unit_id: params[:church_unit_id])
    person = current_street_person
    if person
      People::Transfer.call(person:, ward:)
      remember_ward(ward)
      if (pack_id = session.delete(:pending_street_pack_id)).present?
        frame = Quizzes::StartPack.call(
          device_digest: street_device_digest,
          person_id: person.id,
          pack_id: pack_id
        )
        session[:street_play_run_id] = frame.run.id
        redirect_to jugar_path, notice: I18n.t("flashes.ready_to_play", name: person.given_name, ward: ward.name)
      else
        redirect_after_ward_pick(ward)
      end
    else
      remember_ward(ward)
      redirect_to root_path, notice: I18n.t("flashes.street_ward_selected_guest", ward: ward.name)
    end
  rescue People::Error => error
    redirect_to search_path(cambiar: 1), alert: error.message
  end

  private

    def redirect_after_ward_pick(ward)
      destination = session.delete(:street_return)
      path = case destination
      when "leaderboard" then street_leaderboard_path
      when "desafios" then street_challenges_path
      else root_path
      end
      redirect_to path, notice: I18n.t("flashes.street_ward_changed", ward: ward.name)
    end
end
