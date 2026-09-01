require "test_helper"

class Hubs::ChallengeCardTest < ActiveSupport::TestCase
  Campus = Struct.new(:incoming, :active, keyword_init: true)
  Invitation = Struct.new(:id, :expires_at, keyword_init: true)
  InvitationItem = Struct.new(:invitation, :other, :token, keyword_init: true)
  Duel = Struct.new(:id, :updated_at, keyword_init: true) do
    def to_param = id.to_s
  end
  DuelItem = Struct.new(:duel, :other, :state, :mine, :theirs, keyword_init: true)
  Person = Struct.new(:display_name, keyword_init: true)

  test "selects the earliest named invitation" do
    later = invitation_item(id: 9, token: "later", name: "Maya", expires_at: 3.days.from_now)
    earliest = invitation_item(id: 4, token: "earliest", name: "Ana", expires_at: 1.day.from_now)

    card = Hubs::ChallengeCard.call(campus: Campus.new(incoming: [ later, earliest ], active: []))

    assert_equal :challenge, card.kind
    assert_equal :incoming, card.state
    assert_equal "Ana", card.title
    assert_equal Rails.application.routes.url_helpers.street_challenge_accept_path("earliest"), card.path
    assert_equal :post, card.method
    assert_equal earliest.invitation.expires_at, card.due_at
  end

  test "prefers a current turn over ready and ignores waiting or resolved duels" do
    current_turn = duel_item(id: 11, state: :your_turn, name: "Ingrid", updated_at: 2.hours.ago, mine: nil, theirs: 170)
    ready = duel_item(id: 12, state: :ready, name: "Lucas", updated_at: 1.minute.ago, mine: nil, theirs: nil)
    waiting = duel_item(id: 13, state: :waiting, name: "Carmen", updated_at: Time.current, mine: 210, theirs: nil)
    result = duel_item(id: 14, state: :resolved, name: "Pili", updated_at: Time.current, mine: 200, theirs: 180)

    card = Hubs::ChallengeCard.call(
      campus: Campus.new(incoming: [], active: [ ready, result, waiting, current_turn ])
    )

    assert_equal :your_turn, card.state
    assert_equal "Ingrid", card.title
    assert_equal Rails.application.routes.url_helpers.street_duel_path(11), card.path
    assert_equal :get, card.method
    assert_nil card.mine
    assert_equal 170, card.theirs
  end

  test "returns nothing when Campus has no named action for this player" do
    card = Hubs::ChallengeCard.call(
      campus: Campus.new(
        incoming: [ invitation_item(id: 1, token: "anonymous", name: nil, expires_at: 1.hour.from_now) ],
        active: [ duel_item(id: 2, state: :waiting, name: "Maya", updated_at: Time.current, mine: 90, theirs: nil) ]
      )
    )

    assert_nil card
  end

  private

    def invitation_item(id:, token:, name:, expires_at:)
      InvitationItem.new(
        invitation: Invitation.new(id:, expires_at:),
        token:,
        other: Person.new(display_name: name)
      )
    end

    def duel_item(id:, state:, name:, updated_at:, mine:, theirs:)
      DuelItem.new(
        duel: Duel.new(id:, updated_at:),
        state:,
        other: Person.new(display_name: name),
        mine:,
        theirs:
      )
    end
end
