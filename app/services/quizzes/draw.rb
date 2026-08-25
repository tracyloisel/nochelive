module Quizzes
  class Draw
    Frame = Struct.new(:run, :pack, :question, :answer, :tally, :complete, keyword_init: true) do
      def settled? = answer.present? && !done?
      def done? = run.finished?
      def asking? = !done? && answer.nil?
    end

    def self.call(device_digest:, person_id: nil)
      new(device_digest:, person_id:).call
    end

    def self.frame(run)
      pack = run.pack
      question = pack.question_at(run.position)
      answer = run.quiz_answers.find_by(question_id: question.id)
      complete = run.finished? ? Complete.summary(run) : nil
      tally = answer && !run.finished? ? Tally.call(pack_id: pack.id, question_id: question.id) : nil
      Frame.new(run:, pack:, question:, answer:, tally:, complete:)
    end

    def initialize(device_digest:, person_id: nil)
      @digest = device_digest.to_s
      @person_id = person_id
      raise ArgumentError, "device required" if @digest.blank?
    end

    def call
      open = scoped.open_runs.order(:id).last
      return self.class.frame(open) if open

      last = scoped.order(:id).last
      return self.class.frame(last) if last&.finished?

      self.class.frame(start_pack(next_pack_id(last)))
    end

    def start_next(after:)
      self.class.frame(start_pack(next_pack_id(after)))
    end

    private

      def scoped
        QuizRun.where(device_digest: @digest, person_id: @person_id)
      end

      def next_pack_id(last)
        ids = QuizDefinition.catalog.pack_ids
        return ids.first unless last

        idx = ids.index(last.pack_id) || -1
        ids[(idx + 1) % ids.size]
      end

      def start_pack(pack_id)
        pack = QuizDefinition.catalog.find_pack(pack_id)
        question = pack.question_at(1)
        QuizRun.create!(
          device_digest: @digest,
          person_id: @person_id,
          pack_id: pack_id,
          position: 1,
          score: 0,
          status: "open",
          opened_at: Time.current,
          ends_at: question.timed? ? question.duration.seconds.from_now : nil
        )
      end
  end
end
