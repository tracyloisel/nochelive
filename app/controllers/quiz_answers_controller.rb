class QuizAnswersController < ApplicationController
  include StreetQuiz
  before_action :require_street_identity, :load_street_run

  def create
    track_first_invited_question if @run.position == 1 && @run.quiz_answers.none?
    previous_score = @run.score
    Quizzes::Submit.call(run: @run, choice_key: params[:choice].to_s)
    run = @run.reload
    Quizzes::DuelRaceBroadcast.progress(run:, previous_score:)
    replace_street_result(run, previous_score:)
  rescue RuntimeError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    redirect_to jugar_path
  end

  private

    def track_first_invited_question
      invitation = DuelInvitation.where(status: "claimed", claimed_by_person: current_street_person)
        .order(claimed_at: :desc, id: :desc)
        .first
      return unless invitation

      Quizzes::ViralTrack.call(
        name: "first_question_started",
        device_digest: street_digest,
        invitation:,
        duel: invitation.street_duel,
        person: current_street_person,
        source: "invite",
        event_key: "first-question-started:#{invitation.id}:#{current_street_person.id}"
      )
    end
end
