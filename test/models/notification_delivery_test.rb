require "test_helper"

class NotificationDeliveryTest < ActiveSupport::TestCase
  test "requires an internal destination and the subscription person" do
    delivery = notification_deliveries(:carmen_duel_result).dup
    delivery.dedupe_key = "invalid-delivery"
    delivery.destination = "https://attacker.example/path"
    delivery.person = people(:pili)

    refute delivery.valid?
    assert delivery.errors[:destination].any?
    assert delivery.errors[:person].any?
  end

  test "rejects network-path backslash and newline ambiguities" do
    delivery = notification_deliveries(:carmen_duel_result).dup
    delivery.dedupe_key = "ambiguous-destination"

    [ "/\\attacker.example/path", "/desafio/safe\nhttps://attacker.example" ].each do |destination|
      delivery.destination = destination
      refute delivery.valid?, destination.inspect
      assert delivery.errors[:destination].any?
    end
  end
end
