require "test_helper"

class Hubs::InvitationsTest < ActiveSupport::TestCase
  test "shows only completed shares and advances through the invitation states" do
    person = people(:pili)
    sent = street_duels(:pending_challenge)
    ViralEvent.create!(
      name: "invite_share_completed",
      device_digest: "sender-device",
      street_duel: sent,
      person: person,
      source: "native"
    )
    opened = StreetDuel.create!(
      challenger_person: person,
      ward: wards(:demo),
      challenger_ward: wards(:demo),
      pack_id: "placas",
      token: "opened-invitation-token",
      status: "challenger_done",
      challenger_score: 72,
      expires_at: 3.days.from_now
    )
    %w[invite_share_completed invite_link_opened].each do |name|
      ViralEvent.create!(name:, device_digest: "sender-device", street_duel: opened, person: person)
    end
    canceled = StreetDuel.create!(
      challenger_person: person,
      ward: wards(:demo),
      challenger_ward: wards(:demo),
      pack_id: "ovejas",
      token: "canceled-share-token",
      status: "challenger_done",
      expires_at: 3.days.from_now
    )
    ViralEvent.create!(name: "invite_share_opened", device_digest: "sender-device", street_duel: canceled, person: person)

    result = Hubs::Invitations.call(person: person)

    assert_equal 2, result.total
    assert_equal 2, result.waiting
    assert_equal %i[opened sent], result.items.map(&:state)
    assert_equal 72, result.items.first.score
    assert_equal "/desafio/opened-invitation-token?src=reminder", result.items.first.url
    refute_includes result.items.map(&:token), canceled.token
  end

  test "counts friends who joined and marks resolved invitations complete" do
    duel = street_duels(:pili_vs_carmen)
    ViralEvent.create!(
      name: "invite_share_completed",
      device_digest: "sender-device",
      street_duel: duel,
      person: people(:pili)
    )

    result = Hubs::Invitations.call(person: people(:pili))

    assert_equal 1, result.joined
    assert_equal :completed, result.items.first.state
    assert_equal "Carmen", result.items.first.friend_name
  end
end
