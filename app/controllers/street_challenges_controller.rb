class StreetChallengesController < ApplicationController
  include StreetQuiz

  before_action :load_invitation, only: %i[show accept decline received opened]
  before_action :require_campus_person, only: %i[index duel rematch]
  before_action :load_member_duel, only: %i[duel rematch]

  def index
    remember_device
    touch_street_presence
    remember_ward(current_street_person.ward) if current_street_person.ward

    @q = params[:q].to_s.strip
    @campus = Quizzes::DuelCampus.call(person: current_street_person)
    @duel_summary = Quizzes::DuelCampusSummary.call(person: current_street_person, campus: @campus)
    @friends = Quizzes::DuelCampusFriends.call(person: current_street_person, q: @q)
    @world = Quizzes::World.call(device_digest: street_digest, person_id: current_street_person.id)
    @next_pack = @world.packs.find { |pack| pack.state.in?(%i[open current]) } ||
      @world.packs.find { |pack| pack.state == :available } ||
      @world.packs.reverse.find { |pack| pack.state == :finished }
    Quizzes::DuelCampusVisit.call(person: current_street_person, device_digest: street_digest)
    prompt_context = session.delete(:push_prompt_context).presence
    if prompt_context
      eligibility = Notifications::PromptEligibility.call(
        person: current_street_person,
        device_token:,
        category: "challenges",
        context: prompt_context,
        priority_blocked: @campus.incoming.any?
      )
      @push_prompt = { category: "challenges", context: prompt_context } if eligibility.eligible
    end
  end

  def show
    remember_device
    @screen = Quizzes::DuelInvitationScreen.call(
      token: params[:token],
      person: current_street_person,
      source: params[:src],
      device_digest: street_digest
    )
    unless @screen
      redirect_to root_path, alert: I18n.t("duel_campus.errors.not_found")
      return
    end

    @campus = Quizzes::DuelCampus.call(person: current_street_person) if current_street_person
  end

  def create
    remember_device
    person = current_street_person
    return challenge_error(I18n.t("duel_campus.errors.identity"), :unauthorized) unless person

    opponent = opponent_from_params(person)
    if params[:opponent_id].present? && opponent.nil?
      return challenge_error(I18n.t("duel_campus.errors.scope"), :unprocessable_entity)
    end
    run = completed_run_from_params(person)
    result = Quizzes::DuelInvitationCreate.call(
      challenger_person: person,
      recipient_person: opponent,
      run:,
      source: params[:source] || "campus",
      channel: params[:channel]
    )

    return respond_with_existing_duel(result.duel) if result.duel

    session[:push_prompt_context] = "duel_invitation_sent" if opponent
    respond_to do |format|
      format.json { render json: invitation_payload(result), status: result.reused ? :ok : :created }
      format.html do
        notice = if opponent
          I18n.t("duel_campus.notices.named_sent", name: opponent.display_name)
        else
          I18n.t("duel_campus.notices.link_ready")
        end
        redirect_to street_challenges_path, notice:
      end
    end
  rescue ActiveRecord::RecordNotFound
    challenge_error(I18n.t("duel_campus.errors.score"), :unprocessable_entity)
  rescue Quizzes::DuelInvitationCreate::Denied => error
    challenge_error(
      I18n.t("duel_campus.errors.#{error.code}", default: I18n.t("duel_campus.errors.create")),
      :unprocessable_entity
    )
  end

  def received
    person = current_street_person
    return head :unauthorized unless person

    acknowledged = Quizzes::DuelInvitationReceipt.call(
      invitation: @invitation,
      person:,
      state: :seen,
      device_digest: street_digest,
      source: "invitation_page"
    )
    head acknowledged ? :no_content : :forbidden
  end

  def opened
    acknowledged = Quizzes::DuelInvitationReceipt.call(
      invitation: @invitation,
      person: current_street_person,
      state: :human_opened,
      device_digest: street_digest,
      source: params[:src] || "invitation_page",
      channel: params[:channel]
    )
    head acknowledged ? :no_content : :forbidden
  end

  def accept
    person = current_street_person
    unless person
      session[:pending_duel_invitation_token] = params[:token]
      clear_street_guest
      redirect_to street_profile_path(quick: 1, fresh: 1), alert: I18n.t("duel_campus.errors.identity")
      return
    end

    result = Quizzes::DuelInvitationClaim.call(
      invitation: @invitation,
      person:,
      device_digest: street_digest
    )
    session.delete(:pending_duel_invitation_token)
    if result.duel.run_for(person)&.finished?
      redirect_to street_duel_path(result.duel), notice: I18n.t("duel_campus.notices.already_active")
      return
    end

    frame = Quizzes::Draw.call(device_digest: street_digest, person_id: person.id, ward: person.ward)
    session[:street_play_run_id] = frame.run.id
    notice = result.created ? I18n.t("duel_campus.notices.accepted") : I18n.t("duel_campus.notices.already_active")
    redirect_to jugar_path, notice:
  rescue Quizzes::DuelInvitationClaim::Expired
    session.delete(:pending_duel_invitation_token)
    redirect_to street_challenges_path, alert: I18n.t("duel_campus.errors.expired")
  rescue Quizzes::DuelInvitationClaim::Taken
    redirect_to street_challenges_path, alert: I18n.t("duel_campus.errors.taken")
  end

  def decline
    person = current_street_person
    unless person
      redirect_to street_profile_path(quick: 1, fresh: 1), alert: I18n.t("duel_campus.errors.identity")
      return
    end

    Quizzes::DuelInvitationDecline.call(invitation: @invitation, person:)
    redirect_to street_challenges_path, notice: I18n.t("duel_campus.notices.declined")
  rescue Quizzes::DuelInvitationDecline::Expired
    redirect_to street_challenges_path, alert: I18n.t("duel_campus.errors.expired")
  rescue Quizzes::DuelInvitationDecline::Taken
    redirect_to street_challenges_path, alert: I18n.t("duel_campus.errors.taken")
  end

  def duel
    campus = Quizzes::DuelCampus.call(person: current_street_person)
    @item = (campus.results + campus.active).find { |item| item.duel.id == @duel.id }
    if @duel.resolved?
      Quizzes::DuelResultSeen.call(duel: @duel, person: current_street_person, device_digest: street_digest)
    end
  end

  def rematch
    unless @duel.resolved?
      redirect_to street_duel_path(@duel), alert: I18n.t("duel_campus.errors.rematch")
      return
    end

    opponent = @duel.other_person_for(current_street_person)
    result = Quizzes::DuelInvitationCreate.call(
      challenger_person: current_street_person,
      recipient_person: opponent,
      rematch_of_duel: @duel,
      source: "duel_result",
      channel: "noche"
    )
    notice = if result.duel
      I18n.t("duel_campus.notices.already_active")
    else
      I18n.t("duel_campus.notices.rematch_sent", name: opponent.display_name)
    end
    redirect_to street_challenges_path, notice:
  rescue Quizzes::DuelInvitationCreate::Denied
    redirect_to street_duel_path(@duel), alert: I18n.t("duel_campus.errors.rematch")
  end

  private

    def load_invitation
      @invitation = DuelInvitation.find_by_token(params[:token])
      redirect_to(root_path, alert: I18n.t("duel_campus.errors.not_found")) unless @invitation
    end

    def require_campus_person
      return if current_street_person

      session[:street_return] = "desafios"
      redirect_to street_profile_path(quick: 1, fresh: 1), alert: I18n.t("duel_campus.errors.identity")
    end

    def load_member_duel
      @duel = StreetDuel.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @duel.includes_person?(current_street_person)
    rescue ActiveRecord::RecordNotFound
      redirect_to street_challenges_path, alert: I18n.t("duel_campus.errors.not_found")
    end

    def opponent_from_params(person)
      id = params[:opponent_id].presence
      return unless id
      return unless person.ward

      Quizzes::StakeScope.people_for(ward: person.ward).find_by(id:)
    end

    def completed_run_from_params(person)
      id = params[:run_id].presence
      return unless id

      QuizRun.street.finished.find_by!(id:, person_id: person.id)
    end

    def invitation_payload(result)
      {
        invitation_id: result.invitation.id,
        token: result.token,
        url: street_challenge_url(result.token),
        state: result.invitation.receipt_state,
        reused: result.reused
      }
    end

    def respond_with_existing_duel(duel)
      respond_to do |format|
        format.json { render json: { duel_id: duel.id, url: street_duel_url(duel), state: "active", reused: true } }
        format.html { redirect_to street_duel_path(duel), notice: I18n.t("duel_campus.notices.already_active") }
      end
    end

    def challenge_error(message, status)
      respond_to do |format|
        format.json { render json: { error: message }, status: }
        format.html { redirect_to street_challenges_path, alert: message }
      end
    end
end
