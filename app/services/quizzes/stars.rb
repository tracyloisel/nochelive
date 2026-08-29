module Quizzes
  class Stars
    MAX_SCORE = StreakReward.max_pack_score

    def self.call(score:)
      score = score.to_i
      stars = 1
      stars = 2 if score >= (MAX_SCORE * 0.6).ceil
      stars = 3 if score >= (MAX_SCORE * 0.85).ceil
      stars
    end
  end
end
