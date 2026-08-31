class QuizAnswersController < ApplicationController
  include StreetQuiz
  before_action :load_quiz_run, :authorize_quiz_run

  def create
    track_first_invited_question if @run.street? && @run.position == 1 && @run.quiz_answers.none?
    previous_score = @run.score
    Quizzes::Submit.call(run: @run, choice_key: params[:choice].to_s)
    run = @run.reload
    if run.live?
      answer = run.current_answer
      Nights::Events.after_answer(run:, answer:, previous_score:) if answer
    else
      Quizzes::DuelRaceBroadcast.progress(run:, previous_score:)
    end
    replace_street_result(run, previous_score:)
  rescue RuntimeError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    redirect_to quiz_error_path
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
