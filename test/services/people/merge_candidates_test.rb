require "test_helper"

class People::MergeCandidatesTest < ActiveSupport::TestCase
  test "lists only homonyms from the same ward with their score and device status" do
    current = people(:carmen_lopez)
    candidate = people(:carmen_garcia)
    candidate.person_devices.create!(device_token: "shared-phone")

    cards = People::MergeCandidates.call(person: current, device_token: "shared-phone")

    assert_equal [ candidate ], cards.map(&:person)
    assert_equal 208, cards.first.score
    assert cards.first.on_device
    assert cards.first.claimable
    assert_not_includes cards.map(&:person), people(:pili)
  end

  test "marks an old profile without a year or device as needing presenter help" do
    current = people(:carmen_lopez)
    candidate = people(:carmen_garcia)
    candidate.update!(favorite_year: nil)

    card = People::MergeCandidates.call(person: current, device_token: "new-phone").sole

    assert_not card.on_device
    assert_not card.claimable
  end
end
