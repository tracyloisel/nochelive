module Quizzes
  class HitStreak
    Result = Struct.new(:count, :grew, :broke, :broken_count, :shout_key, :sfx, :tier, keyword_init: true)
    SHOUTS = { 1 => "start", 2 => "two", 3 => "three", 4 => "four", 5 => "five", 10 => "ten" }.freeze

    def self.call(run:)
      new(run:).call
    end

    def self.max_count(run:)
      new(run:).max_count
    end

    def initialize(run:)
      @run = run
    end

    def call
      sequence = verdicts(upto)
      count = tail(sequence)
      last = sequence.last
      previous_count = tail(sequence[0...-1])
      grew = live_settle? && last == true
      broke = live_settle? && last == false && previous_count.positive?
      Result.new(
        count:,
        grew:,
        broke:,
        broken_count: broke ? previous_count : 0,
        shout_key: grew ? SHOUTS[count] : nil,
        sfx: nil,
        tier: tier_for(count)
      )
    end

    def max_count
      best = 0
      current = 0
      verdicts(upto).each do |ok|
        if ok == true
          current += 1
          best = current if current > best
        else
          current = 0
        end
      end
      best
    end

    private

      def live_settle?
        @run.settled? && !@run.finished?
      end

      def upto
        @run.settled? || @run.finished? ? @run.position : @run.position - 1
      end

      def verdicts(upto)
        return [] if upto < 1

        pack = @run.pack
        answers = @run.quiz_answers.index_by(&:question_id)
        (1..upto).map { |index| answers[pack.question_at(index).id]&.correct }
      end

      def tail(list)
        count = 0
        Array(list).reverse_each do |ok|
          break unless ok == true

          count += 1
        end
        count
      end

      def tier_for(count)
        return "legend" if count >= 10
        return "blaze" if count >= 5
        return "hot" if count >= 3
        return "glow" if count >= 2
        return "spark" if count >= 1

        "idle"
      end
  end
end
