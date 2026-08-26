class StreetLeaderboardsController < ApplicationController
  include StreetQuiz

  helper_method :liga_path_for

  def show
    remember_device
    touch_street_presence
    @visit = params[:code].present?
    begin
      @board_ward = @visit ? Wards::Enter.call(code: params[:code]) : current_ward
    rescue People::Error
      return redirect_to root_path, alert: I18n.t("errors.people.ward_missing")
    end
    return redirect_to root_path unless @board_ward

    person = current_street_person
    person = nil unless person&.ward_id == @board_ward.id
    pack_id = pack_id_param
    page = [ params[:page].to_i, 1 ].max
    offset = (page - 1) * Quizzes::Leaderboard::LIMIT_PAGE
    @you = person
    @pack_id = pack_id
    @board = Quizzes::Leaderboard.call(
      ward: @board_ward,
      pack_id:,
      person:,
      limit: Quizzes::Leaderboard::LIMIT_PAGE,
      offset:,
      q: params[:q]
    )
    @page = page
    @q = params[:q].to_s.strip
    @duel_incoming = person ? Quizzes::ChallengeInbox.actionable_count(person:) : 0
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
