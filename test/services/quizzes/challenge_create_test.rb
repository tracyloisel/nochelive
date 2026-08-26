require "test_helper"

class Quizzes::ChallengeCreateTest < ActiveSupport::TestCase
  test "creates pending duel" do
    person = people(:pili)
    result = Quizzes::ChallengeCreate.call(
      challenger_person: person,
      ward: person.ward,
      pack_id: "coronas"
    )
    assert result.duel.pending?
    assert result.share_url.include?(result.duel.token)
  end
end
