require "test_helper"

class Quizzes::ChallengeBoardTest < ActiveSupport::TestCase
  test "offers rivals from every listed ward in the stake" do
    alicante = Ward.create!(
      name: "Rama Alicante", code: "ALICANTE", emblem: "paloma", city: "Alicante",
      country_code: "ES", listed: true, stake_unit_id: wards(:demo).stake_unit_id,
      presenter_token_digest: GameSession.digest_token("rama-alicante")
    )
    lucas = alicante.people.create!(given_name: "Lucas", family_name: "Costa", avatar_key: "gato", favorite_year: 2010)
    result = Quizzes::ChallengeBoard.call(ward: wards(:demo), person: people(:pili), pack_id: "coronas")

    assert_includes result.rivals.map(&:person), lucas
    assert_equal alicante, result.rivals.find { |row| row.person == lucas }.ward
    assert_equal "coronas", result.pack_id
  end
end
