module AdminApi
  class WardsController < BaseController
    def index
      query = params[:q].to_s.strip
      scope = Ward.order(:name)
      scope = scope.where("name ILIKE :q OR code ILIKE :q OR city ILIKE :q", q: "%#{Ward.sanitize_sql_like(query)}%") if query.present?
      render json: { wards: scope.limit(25).map { |ward| ward_json(ward) } }
    end

    def show
      ward = find_ward
      scores = Quizzes::Leaderboard.pack_best_totals(ward:)
      people = ward.people.order(:given_name, :family_name).limit(100).map do |person|
        {
          id: person.id,
          name: person.display_name,
          avatar: person.avatar_key,
          points: scores[person.id].to_i,
          created_at: person.created_at.iso8601
        }
      end
      render json: { ward: ward_json(ward).merge(people:) }
    end

    def rotate_presenter_token
      ward = find_ward
      token = Array.new(16) { GameSession::CODE_CHARS.sample }.join
      ward.update!(presenter_token_digest: GameSession.digest_token(token))
      admin_audit!("rotate_presenter_token", ward_id: ward.id)
      render json: { ward: ward_json(ward), presenter_token: token, warning: "shown_once" }
    end

    def stats
      ward = find_ward
      person_ids = ward.people.select(:id)
      scores = Quizzes::Leaderboard.pack_best_totals(ward:)
      answers = QuizAnswer.joins(:quiz_run).where(quiz_runs: { person_id: person_ids })
      duels = StreetDuel.where(challenger_person_id: person_ids)
        .or(StreetDuel.where(opponent_person_id: person_ids))
      render json: {
        ward: ward_json(ward).merge(
          live_people: Presences::Registry.online_person_ids(ward_id: ward.id).size,
          players_with_points: scores.size,
          total_best_points: scores.values.sum,
          finished_quiz_runs: QuizRun.finished.where(person_id: person_ids).count,
          quiz_answers: answers.count,
          correct_answers: answers.where(correct: true).count,
          completed_study_runs: StudyRun.completed.where(person_id: person_ids).count,
          completed_readings: ReadingProgress.where(person_id: person_ids, status: "completed").count,
          duels: duels.count,
          invitations_sent: DuelInvitation.where(challenger_person_id: person_ids).count
        )
      }
    end

    private

      def find_ward
        Ward.find_by!(code: Ward.normalize_code(params[:code]))
      end

      def ward_json(ward)
        {
          id: ward.id,
          code: ward.code,
          name: ward.name,
          city: ward.city,
          people_count: ward.people.count,
          nights_count: ward.game_sessions.count
        }
      end
  end
end
