require "test_helper"

class Quizzes::ViralTrackTest < ActiveSupport::TestCase
  test "keeps only funnel-safe properties" do
    event = Quizzes::ViralTrack.call(
      name: "invite_link_opened",
      device_digest: "digest",
      duel: street_duels(:pending_challenge),
      source: "native",
      properties: { pack_id: "coronas", phone: "+341234", secret: "no" }
    )

    assert_equal({ "pack_id" => "coronas" }, event.properties)
  end

  test "ignores names outside the funnel" do
    assert_nil Quizzes::ViralTrack.call(name: "page_view", device_digest: "digest")
  end
end
