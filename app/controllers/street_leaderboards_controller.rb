class StreetLeaderboardsController < ApplicationController
  include StreetQuiz

  def show
    remember_device
    ward = current_ward
    person = current_street_person
    return redirect_to root_path unless ward

    pack_id = pack_id_param
    page = [ params[:page].to_i, 1 ].max
    offset = (page - 1) * Quizzes::Leaderboard::LIMIT_PAGE
    @pack_id = pack_id
    @board = Quizzes::Leaderboard.call(
      ward:,
      pack_id:,
      person:,
      limit: Quizzes::Leaderboard::LIMIT_PAGE,
      offset:,
      q: params[:q]
    )
    @page = page
    @q = params[:q].to_s.strip
  end

  private

    def pack_id_param
      id = params[:pack_id].presence
      return nil unless id
      return nil unless QuizDefinition.catalog.pack_ids.include?(id)

      id
    end
end
