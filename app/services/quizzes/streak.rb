module Quizzes
  class Streak
    Result = Struct.new(:days, keyword_init: true)

    def self.call(person_id: nil, device_digest: nil)
      new(person_id:, device_digest:).call
    end

    def initialize(person_id: nil, device_digest: nil)
      @person_id = person_id
      @device_digest = device_digest
    end

    def call
      scope = QuizRun.all
      scope = scope.where(person_id: @person_id) if @person_id
      scope = scope.where(device_digest: @device_digest) if @device_digest && @person_id.nil?
      dates = scope.pluck(:opened_at).compact.map { |t| t.to_date }
      dates += QuizAnswer.joins(:quiz_run).merge(scope).pluck("quiz_answers.created_at").map { |t| t.to_date }
      days = consecutive_days_from(dates.uniq.sort.reverse)
      Result.new(days:)
    end

    private

      def consecutive_days_from(sorted_desc)
        return 0 if sorted_desc.empty?

        streak = 1
        cursor = sorted_desc.first
        sorted_desc.drop(1).each do |day|
          break unless cursor - 1.day == day

          streak += 1
          cursor = day
        end
        streak
      end
  end
end
