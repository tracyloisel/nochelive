class StreetChallengesController < ApplicationController
  include StreetQuiz

  before_action :load_duel, only: [ :show, :accept, :decline ]

  def index
    remember_device
    touch_street_presence
    person = current_street_person
    unless person
      session[:street_return] = "desafios"
      redirect_to street_profile_path(quick: 1, fresh: 1)
      return
    end
    unless person.ward
      session[:street_return] = "desafios"
      redirect_to search_path(cambiar: 1), alert: I18n.t("flashes.ward_required_challenges")
      return
    end

    remember_ward(person.ward) unless current_ward&.id == person.ward_id
    ward = person.ward

    @q = params[:q].to_s.strip
    @pack_id = Quizzes::World.call(device_digest: street_digest, person_id: person.id).current_pack_id
    @board = Quizzes::ChallengeBoard.call(ward:, person:, pack_id: @pack_id)
    @inbox = @board.inbox
    @rivals = @board.rivals
    @rivalry = @board.rivalry
    @head_to_head = @board.head_to_head
    @incoming_action = @inbox.incoming.any? { |item| item.phase == :accept || item.phase == :play }
  end

  def show
    @pack = QuizDefinition.catalog.find_pack(@duel.pack_id)
    @challenger = @duel.challenger_person
    @challenge = Quizzes::ChallengeScreen.call(duel: @duel, person: current_street_person)
    remember_ward(@duel.challenger_ward || @duel.ward) if current_street_person.nil? && current_ward.nil?
    Quizzes::ViralTrack.call(
      name: "invite_link_opened",
      device_digest: street_digest,
      duel: @duel,
      person: current_street_person,
      source: params[:src],
      properties: { pack_id: @duel.pack_id, role: @challenge&.role }
    ) unless @challenge&.role == :challenger
    redirect_to jugar_path if @challenge&.phase == :play
  end

  def create
    remember_device
    person = current_street_person
    ward = person&.ward
    html = request.format.html?
    unless person
      return redirect_to street_profile_path(quick: 1, fresh: 1), alert: I18n.t("street.duel_sign_in") if html

      return render json: { error: I18n.t("street.duel_sign_in") }, status: :unauthorized
    end
    unless ward
      session[:street_return] = "desafios"
      return redirect_to search_path(cambiar: 1), alert: I18n.t("flashes.ward_required_challenges") if html

      return render json: { error: I18n.t("flashes.ward_required_challenges") }, status: :unprocessable_entity
    end

    remember_ward(ward) unless current_ward&.id == ward.id

    opponent = opponent_from_params(ward)
    if html && opponent.nil?
      redirect_to street_challenges_path, alert: I18n.t("street.duel_pick")
      return
    end

    pack_id = params[:pack_id].presence || params[:pack].presence || Quizzes::World.call(device_digest: street_digest, person_id: person.id).current_pack_id
    completed_run = if params[:run_id].present?
      QuizRun.finished.find_by(id: params[:run_id], person_id: person.id, pack_id:)
    end
    if params[:run_id].present? && completed_run.nil?
      error = I18n.t("street.duel_score")
      return redirect_to street_challenges_path, alert: error if html

      return render json: { error: }, status: :unprocessable_entity
    end
    result = Quizzes::ChallengeCreate.call(
      challenger_person: person,
      ward:,
      pack_id:,
      device_digest: street_digest,
      run: completed_run,
      opponent_person: opponent
    )
    if opponent && StreetDuel.where(status: "resolved")
        .where("(challenger_person_id = :me AND opponent_person_id = :them) OR (challenger_person_id = :them AND opponent_person_id = :me)", me: person.id, them: opponent.id)
        .where.not(id: result.duel.id).exists?
      Quizzes::ViralTrack.call(
        name: "rematch_started",
        device_digest: street_digest,
        duel: result.duel,
        person:,
        source: params[:source],
        properties: { pack_id: result.duel.pack_id }
      )
    end
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
      stake: I18n.t("street.duel_ward"),
      score: I18n.t("street.duel_score"),
      played: I18n.t("street.duel_played")
    }[error.code] || I18n.t("street.duel_create_failed")
    return redirect_to street_challenges_path, alert: alert if request.format.html?

    render json: { error: alert }, status: :unprocessable_entity
  end

  def accept
    person = current_street_person
    unless person
      session[:pending_duel_token] = @duel.token
      remember_ward(@duel.challenger_ward || @duel.ward)
      clear_street_guest
      redirect_to street_profile_path(quick: 1, fresh: 1), alert: I18n.t("street.duel_sign_in")
      return
    end
    unless person.ward
      session[:pending_duel_token] = @duel.token
      session[:street_return] = "desafios"
      redirect_to search_path(cambiar: 1), alert: I18n.t("flashes.ward_required_challenges")
      return
    end

    Quizzes::ChallengeAccept.call(duel: @duel, opponent_person: person, device_digest: street_digest)
    Quizzes::ViralTrack.call(
      name: "challenge_started",
      device_digest: street_digest,
      duel: @duel,
      person:,
      source: "invite",
      properties: { pack_id: @duel.pack_id, role: "opponent" }
    )
    session.delete(:pending_duel_token)
    redirect_to jugar_path
  rescue Quizzes::ChallengeAccept::Expired
    session.delete(:pending_duel_token)
    redirect_to root_path, alert: I18n.t("street.duel_expired")
  rescue Quizzes::ChallengeAccept::Taken
    redirect_to street_challenges_path, alert: I18n.t("street.duel_taken")
  end

  def decline
    person = current_street_person
    unless person
      redirect_to street_profile_path(quick: 1, fresh: 1), alert: I18n.t("street.duel_sign_in")
      return
    end

    Quizzes::ChallengeDecline.call(duel: @duel, opponent_person: person)
    redirect_to street_challenges_path, notice: I18n.t("street.duel_declined")
  rescue Quizzes::ChallengeDecline::Expired
    redirect_to root_path, alert: I18n.t("street.duel_expired")
  rescue Quizzes::ChallengeDecline::Taken
    redirect_to street_challenges_path, alert: I18n.t("street.duel_taken")
  end

  private

    def load_duel
      @duel = StreetDuel.find_by!(token: params[:token])
      return unless @duel.expired? && !@duel.resolved? && !@duel.declined?

      redirect_to root_path, alert: I18n.t("street.duel_expired")
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: I18n.t("street.duel_not_found")
    end

    def opponent_from_params(ward)
      id = params[:opponent_id].presence
      return unless id

      Quizzes::StakeScope.people_for(ward:).find_by(id:)
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
end
