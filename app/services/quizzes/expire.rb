module Quizzes
  class Expire
    def self.call(run:)
      new(run:).call
    end

    def initialize(run:)
      @run = run
    end

    def call
      return @run.current_answer if @run.settled?
      raise "Quiz closed" unless @run.open?

      Submit.call(run: @run, choice_key: "")
    end
  end
end
