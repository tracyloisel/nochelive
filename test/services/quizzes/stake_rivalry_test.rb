require "test_helper"

class Quizzes::StakeRivalryTest < ActiveSupport::TestCase
  test "compares listed wards in the same stake" do
    alicante = create_stake_ward
    result = Quizzes::StakeRivalry.call(ward: wards(:demo))

    assert_equal wards(:demo), result.home.ward
    assert_equal alicante, result.away.ward
    assert_operator result.home.score, :>=, 0
  end

  test "returns an honest solo state without another ward" do
    result = Quizzes::StakeRivalry.call(ward: wards(:blank))

    assert_nil result.away
    assert_nil result.leader
  end

  private

    def create_stake_ward
      Ward.create!(
        name: "Rama Alicante", code: "ALICANTE", emblem: "paloma", city: "Alicante",
        country_code: "ES", listed: true, stake_unit_id: wards(:demo).stake_unit_id,
        presenter_token_digest: GameSession.digest_token("rama-alicante")
      )
    end
end
