module StreetQuiz
  extend ActiveSupport::Concern

  private

    def street_digest
      remember_device
      GameSession.digest_token(device_token)
    end

    def load_street_run
      @run = QuizRun.find_by!(
        id: params[:quiz_run_id],
        device_digest: street_digest,
        person_id: current_street_person&.id
      )
    end

    def street_draw
      Quizzes::Draw.call(device_digest: street_digest, person_id: current_street_person&.id)
    end

    def replace_street(run = @run)
      street = Quizzes::Draw.frame(run)
      trail = Quizzes::Trail.call(run: street.run)
      person = run.person
      ward = person&.ward
      standings = ward && person ? Quizzes::Standings.call(ward:, person:, pack_id: run.pack_id) : nil
      respond_to do |format|
        format.turbo_stream do
          I18n.with_locale(current_locale) do
            render turbo_stream: turbo_stream.replace(
              "street_quiz",
              partial: "home/street",
              locals: { street: street, street_trail: trail, standings: standings }
            )
          end
        end
        format.html { redirect_to root_path }
      end
    end
end
