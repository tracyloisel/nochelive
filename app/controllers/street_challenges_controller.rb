class StreetChallengesController < ApplicationController
  include StreetQuiz

  before_action :load_duel, only: [ :show, :accept ]

  def index
    remember_device
    touch_street_presence
    ward = current_ward
    person = current_street_person
    unless ward
      redirect_to root_path
      return
    end
    unless person
      session[:street_return] = "desafios"
      redirect_to root_path(ficha: 1)
      return
    end

    @inbox = Quizzes::ChallengeInbox.call(person:)
    @q = params[:q].to_s.strip
    @pack_id = pack_id_param
    @picked_id = params[:person_id].presence&.to_i
    @playable_pack_ids = playable_pack_ids_for(person)
    @pack_id = @playable_pack_ids.first if @pack_id.blank? || @playable_pack_ids.exclude?(@pack_id)
    @pack_bests = pack_bests_for(person, @playable_pack_ids)
    @rivals = rival_rows(ward:, person:)
    @incoming_action = @inbox.incoming.any? { |item| item.phase == :accept || item.phase == :play }
  end

  def show
    @pack = QuizDefinition.catalog.find_pack(@duel.pack_id)
    @challenger = @duel.challenger_person
    @challenge = Quizzes::ChallengeScreen.call(duel: @duel, person: current_street_person)
    redirect_to jugar_path if @challenge&.phase == :play
  end

  def create
    remember_device
    person = current_street_person
    ward = current_ward
    html = request.format.html?
    unless person && ward
      return redirect_to root_path(ficha: 1), alert: I18n.t("street.duel_sign_in") if html

      return render json: { error: I18n.t("street.duel_sign_in") }, status: :unauthorized
    end

    opponent = opponent_from_params(ward)
    if html && opponent.nil?
      redirect_to street_challenges_path, alert: I18n.t("street.duel_pick")
      return
    end

    pack_id = params[:pack_id].presence || params[:pack].presence
    run = pack_id && QuizRun.finished.where(person_id: person.id, pack_id:).order(:id).last

    result = Quizzes::ChallengeCreate.call(
      challenger_person: person,
      ward:,
      pack_id: pack_id || run&.pack_id || Quizzes::World.call(device_digest: street_digest, person_id: person.id).current_pack_id,
      run:,
      opponent_person: opponent
    )
    session[:pending_duel_token] = result.duel.token unless opponent
    pack_title = QuizDefinition.catalog.find_pack(result.duel.pack_id).copy(:title)
    respond_to do |format|
      format.json { render json: { token: result.duel.token, url: street_challenge_url(result.duel.token) } }
      format.html {
        notice = opponent ? I18n.t("street.duel_named", name: opponent.display_name, pack: pack_title) : I18n.t("street.duel_you_sent", pack: pack_title)
        redirect_to street_challenges_path, notice:
      }
    end
  rescue ArgumentError
    return redirect_to street_challenges_path, alert: I18n.t("street.duel_not_found") if request.format.html?

    render json: { error: I18n.t("street.duel_not_found") }, status: :unprocessable_entity
  rescue Quizzes::ChallengeCreate::Denied => error
    alert = {
      self: I18n.t("street.duel_self"),
      ward: I18n.t("street.duel_ward"),
      score: I18n.t("street.duel_score")
    }[error.code] || I18n.t("street.duel_create_failed")
    return redirect_to street_challenges_path, alert: alert if request.format.html?

    render json: { error: alert }, status: :unprocessable_entity
  end

  def accept
    person = current_street_person
    unless person
      session[:pending_duel_token] = @duel.token
      clear_street_guest
      redirect_to root_path(desafio: @duel.token, ficha: 1), alert: I18n.t("street.duel_sign_in")
      return
    end

    Quizzes::ChallengeAccept.call(duel: @duel, opponent_person: person, device_digest: street_digest)
    session.delete(:pending_duel_token)
    redirect_to jugar_path
  rescue Quizzes::ChallengeAccept::Expired
    session.delete(:pending_duel_token)
    redirect_to root_path, alert: I18n.t("street.duel_expired")
  rescue Quizzes::ChallengeAccept::Taken
    redirect_to street_challenges_path, alert: I18n.t("street.duel_taken")
  end

  private

    def load_duel
      @duel = StreetDuel.find_by!(token: params[:token])
      return unless @duel.expired? && !@duel.resolved?

      redirect_to root_path, alert: I18n.t("street.duel_expired")
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: I18n.t("street.duel_not_found")
    end

    def opponent_from_params(ward)
      id = params[:opponent_id].presence
      return unless id

      ward.people.find_by(id:)
    end

    def pack_id_param
      id = params[:pack_id].presence
      return nil unless id
      return nil unless QuizDefinition.catalog.pack_ids.include?(id)

      id
    end

    def playable_pack_ids_for(person)
      QuizDefinition.catalog.pack_ids.select do |pack_id|
        QuizRun.finished.exists?(person_id: person.id, pack_id:)
      end
    end

    def pack_bests_for(person, pack_ids)
      return {} if pack_ids.blank?

      QuizRun.finished.where(person_id: person.id, pack_id: pack_ids).group(:pack_id).maximum(:score)
    end

    def rival_rows(ward:, person:)
      board = Quizzes::Leaderboard.call(ward:, person:, q: @q, limit: 8)
      ranked = board.rows.reject { |row| row.you || row.person.id == person.id }
      return ranked if ranked.any? || @q.present?

      scores = Quizzes::Leaderboard.call(ward:, person:, limit: 50).rows.index_by { |row| row.person.id }
      ward.people.where.not(id: person.id).order(:given_name_key, :family_name_key, :id).limit(8).map do |rival|
        row = scores[rival.id]
        Quizzes::Leaderboard::Row.new(
          rank: row&.rank.to_i,
          person: rival,
          score: row&.score.to_i,
          answered: row&.answered.to_i,
          you: false,
          context: false,
          live: row&.live || false
        )
      end
    end
end
