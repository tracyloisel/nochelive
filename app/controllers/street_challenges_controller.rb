class StreetChallengesController < ApplicationController
  include StreetQuiz

  before_action :load_duel, only: [ :show, :accept ]

  def show
    @pack = QuizDefinition.catalog.find_pack(@duel.pack_id)
    @challenger = @duel.challenger_person
  end

  def create
    remember_device
    person = current_street_person
    ward = current_ward
    return redirect_to root_path, alert: I18n.t("street.duel_sign_in") unless person && ward

    pack_id = params[:pack_id].presence || params[:pack].presence
    run = pack_id && QuizRun.finished.where(
      device_digest: street_digest,
      person_id: person.id,
      pack_id:
    ).order(:id).last

    result = Quizzes::ChallengeCreate.call(
      challenger_person: person,
      ward:,
      pack_id: pack_id || run&.pack_id || Quizzes::World.call(device_digest: street_digest, person_id: person.id).current_pack_id,
      run:
    )
    render json: { token: result.duel.token, url: street_challenge_url(result.duel.token) }
  end

  def accept
    person = current_street_person
    unless person
      session[:pending_duel_token] = @duel.token
      redirect_to root_path(desafio: @duel.token)
      return
    end

    Quizzes::ChallengeAccept.call(duel: @duel, opponent_person: person, device_digest: street_digest)
    redirect_to jugar_path
  rescue Quizzes::ChallengeAccept::Expired
    redirect_to root_path, alert: I18n.t("street.duel_expired")
  rescue Quizzes::ChallengeAccept::Taken
    redirect_to root_path, alert: I18n.t("street.duel_taken")
  end

  private

    def load_duel
      @duel = StreetDuel.not_expired.find_by!(token: params[:token])
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: I18n.t("street.duel_not_found")
    end
end
