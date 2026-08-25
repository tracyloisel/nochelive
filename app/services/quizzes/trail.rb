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
        answer = run.quiz_answers.find_by(question_id: question.id)
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
        QuizRun.finished
          .where(device_digest: @run.device_digest, person_id: @run.person_id, pack_id:)
          .order(:id)
          .last
      end
  end
end
