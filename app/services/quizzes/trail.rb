module Quizzes
  class Trail
    Step = Struct.new(:kind, :id, :label, :position, :state, :pack_id, :run_id, keyword_init: true) do
      def pack? = kind == :pack
      def question? = kind == :question
      def jumpable? = question? && %i[correct wrong current].include?(state)
    end

    def self.call(run:)
      new(run:).call
    end

    def initialize(run:)
      @run = run
      @catalog = QuizDefinition.catalog
      @pack_ids = @catalog.pack_ids
      @current_idx = @pack_ids.index(@run.pack_id) || 0
    end

    def call
      preload_runs_and_answers
      steps = []
      @pack_ids.each_with_index do |pack_id, idx|
        break if idx > @current_idx

        pack = @catalog.find_pack(pack_id)
        steps << pack_step(pack, idx)

        last_pos = idx < @current_idx ? pack.questions.size : @run.position
        run_for_pack = idx < @current_idx ? finished_run_for(pack_id) : @run
        next unless run_for_pack

        (1..last_pos).each do |pos|
          steps << question_step(pack, pos, run_for_pack, idx)
        end
      end
      steps
    end

    private

      def pack_step(pack, idx)
        state = if idx < @current_idx
          :done
        elsif idx == @current_idx
          @run.finished? ? :done : :current
        else
          :future
        end
        Step.new(kind: :pack, id: pack.id, label: pack.copy(:title), state:, pack_id: pack.id, run_id: nil)
      end

      def question_step(pack, position, run, pack_idx)
        question = pack.question_at(position)
        answer = @answers_by_run_and_question[[ run.id, question.id.to_s ]]
        state = if pack_idx < @current_idx
          answer&.correct? ? :correct : :wrong
        elsif position < run.position
          answer&.correct? ? :correct : :wrong
        elsif position == run.position
          if answer
            answer.correct? ? :correct : :wrong
          elsif run.open? && !answer
            :current
          else
            :future
          end
        else
          :future
        end
        Step.new(
          kind: :question,
          id: question.id,
          label: position.to_s,
          position:,
          state:,
          pack_id: pack.id,
          run_id: run.id
        )
      end

      def finished_run_for(pack_id)
        @runs_by_pack[pack_id]
      end

      def preload_runs_and_answers
        prior_pack_ids = @pack_ids.first(@current_idx)
        prior_runs = if prior_pack_ids.empty?
          []
        else
          QuizRun.finished
            .where(device_digest: @run.device_digest, person_id: @run.person_id, pack_id: prior_pack_ids)
            .order(:id)
            .to_a
        end
        @runs_by_pack = prior_runs.index_by(&:pack_id)
        @runs_by_pack[@run.pack_id] = @run
        run_ids = @runs_by_pack.values.map(&:id)
        @answers_by_run_and_question = QuizAnswer.where(quiz_run_id: run_ids)
          .index_by { |answer| [ answer.quiz_run_id, answer.question_id.to_s ] }
      end
  end
end
