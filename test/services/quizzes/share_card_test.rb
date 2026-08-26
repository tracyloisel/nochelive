require "test_helper"

class Quizzes::ShareCardTest < ActiveSupport::TestCase
  test "builds a share url on the given host" do
    person = people(:pili)
    result = Quizzes::ShareCard.call(
      person:,
      ward: person.ward,
      pack_id: "coronas",
      score: 80,
      host: "nochelive.onrender.com"
    )
    assert_includes result.url, "https://nochelive.onrender.com"
    assert_includes result.url, "rama=#{person.ward.code}"
    refute_includes result.url, "example.com"
    refute_includes result.url, "localhost"
  end

  test "falls back to the configured app host" do
    person = people(:pili)
    result = Quizzes::ShareCard.call(
      person:,
      ward: person.ward,
      pack_id: "coronas",
      score: 80
    )
    assert_includes result.url, Rails.configuration.x.app_host
  end
end
