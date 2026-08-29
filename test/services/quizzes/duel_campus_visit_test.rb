require "test_helper"

class Quizzes::DuelCampusVisitTest < ActiveSupport::TestCase
  test "records a daily Campus visit and a single D7 return per friendship" do
    person = people(:pili)
    duel = street_duels(:pili_vs_carmen)
    at = duel.accepted_at + 8.days

    assert_difference("ViralEvent.count", 2) do
      Quizzes::DuelCampusVisit.call(person:, device_digest: "pili-campus", at:)
    end
    assert ViralEvent.exists?(name: "duel_campus_viewed", person:)
    assert ViralEvent.exists?(name: "pair_returned_d7", person:, street_duel: duel)

    assert_no_difference("ViralEvent.count") do
      Quizzes::DuelCampusVisit.call(person:, device_digest: "pili-campus", at: at + 1.hour)
    end
  end
end
