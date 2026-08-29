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
        person_id: current_street_person.id
      )
    end

    def street_draw
      Quizzes::Draw.call(device_digest: street_digest, person_id: current_street_person&.id, ward: current_ward)
    end

    def replace_street(run = @run, previous_score: nil)
      street = Quizzes::Draw.frame(run, ward: current_ward)
      person = run.person
      ward = current_ward || person&.ward
      standings = ward && person ? Quizzes::Standings.call(ward:, person:, pack_id: run.pack_id) : nil
      duel_campus = Quizzes::DuelCampus.call(person:, run: street.run, previous_score:)
      respond_to do |format|
        format.turbo_stream do
          I18n.with_locale(current_locale) do
            render turbo_stream: turbo_stream.replace(
              "street_quiz",
              partial: "home/street",
              locals: {
                street:, standings:, play_context: :jugar, duel_campus:
              }
            )
          end
        end
        format.html { redirect_to jugar_path }
      end
    end

    def replace_street_result(run = @run, previous_score: nil)
      street = Quizzes::Draw.frame(run, ward: current_ward)
      person = run.person
      combo = Quizzes::HitStreak.call(run:)
      chrome = Quizzes::Chrome.call(question: street.question)
      duel_campus = Quizzes::DuelCampus.call(person:, run: street.run, previous_score:)
      bar = Huds::Present.quiz(
        person:,
        pack: street.pack,
        run:,
        street:,
        question: street.question,
        combo:
      )

      respond_to do |format|
        format.turbo_stream do
          I18n.with_locale(current_locale) do
            shell = helpers.street_quiz_shell_attributes(street:, overlay: true, chrome:, combo:)
            state_marker = view_context.tag.section("", id: "street_quiz", class: shell[:class], data: shell[:data])
            state_stream = view_context.turbo_stream_action_tag(
              "quiz_state",
              target: "street_quiz",
              template: state_marker
            )

            render turbo_stream: [
              turbo_stream.action(
                "quiz_deferred_replace",
                "street_quiz_hud_stats",
                partial: "shared/quiz_hud_stats",
                locals: { bar: }
              ),
              turbo_stream.replace(
                "street_quiz_feedback",
                partial: "home/street_overlay_feedback",
                locals: { street:, run:, question: street.question, combo: }
              ),
              turbo_stream.replace(
                "street_quiz_answer_panel",
                partial: "home/street_overlay_answer_panel",
                locals: { street:, run:, pack: street.pack }
              ),
              turbo_stream.replace(
                "street_quiz_actions",
                partial: "home/street_overlay_actions",
                locals: { street:, run:, question: street.question }
              ),
              turbo_stream.replace(
                "street_quiz_timer",
                partial: "home/street_overlay_timer",
                locals: { street:, run:, question: street.question }
              ),
              turbo_stream.action(
                "quiz_deferred_replace",
                "duel_quiz_race",
                partial: "home/duel_campus_rail",
                locals: { campus: duel_campus, run: }
              ),
              state_stream
            ]
          end
        end
        format.html { redirect_to jugar_path }
      end
    end
end
