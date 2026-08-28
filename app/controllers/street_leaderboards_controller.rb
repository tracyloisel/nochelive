class StreetLeaderboardsController < ApplicationController
  include StreetQuiz

  helper_method :liga_path_for

  def show
    remember_device
    touch_street_presence
    unless current_street_person&.ward
      session[:street_return] = "leaderboard"
      redirect_to search_path(cambiar: 1), alert: I18n.t("flashes.ward_required_social")
      return
    end

    remember_ward(current_street_person.ward) unless current_ward&.id == current_street_person.ward_id
    @visit = params[:code].present?
    begin
      @board_ward = @visit ? Wards::Enter.call(code: params[:code]) : current_ward
    rescue People::Error
      return redirect_to root_path, alert: I18n.t("errors.people.ward_missing")
    end
    return redirect_to root_path unless @board_ward

    @scope_wards = Quizzes::StakeScope.wards_for(ward: @board_ward).order(:name)
    @stake_scope = params[:scope] == "stake"
    board_wards = @stake_scope ? @scope_wards : nil
    person = current_street_person
    allowed_ward_ids = @stake_scope ? @scope_wards.ids : [ @board_ward.id ]
    person = nil unless person&.ward_id.in?(allowed_ward_ids)
    pack_id = pack_id_param
    page = [ params[:page].to_i, 1 ].max
    offset = (page - 1) * Quizzes::Leaderboard::LIMIT_PAGE
    @you = person
    @pack_id = pack_id
    @board = Quizzes::Leaderboard.call(
      ward: @board_ward,
      wards: board_wards,
      pack_id:,
      person:,
      limit: Quizzes::Leaderboard::LIMIT_PAGE,
      offset:,
      q: params[:q],
      include_ward: @stake_scope
    )
    @page = page
    @q = params[:q].to_s.strip
    @duel_incoming = person ? Quizzes::ChallengeInbox.actionable_count(person:) : 0
    @duel_pack_id = @pack_id || Quizzes::World.call(device_digest: street_digest, person_id: @you&.id).current_pack_id
  end

  private

    def liga_path_for(**opts)
      opts = opts.compact
      if @visit && @board_ward
        ward_leaderboard_path(@board_ward.code, **opts)
      else
        street_leaderboard_path(**opts)
      end
    end

    def pack_id_param
      id = params[:pack_id].presence
      return nil unless id
      return nil unless QuizDefinition.catalog.pack_ids.include?(id)

      id
    end
end
