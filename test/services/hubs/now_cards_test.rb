require "test_helper"

class Hubs::NowCardsTest < ActiveSupport::TestCase
  Campus = Struct.new(:incoming, :active, keyword_init: true)
  Invitation = Struct.new(:id, :expires_at, keyword_init: true)
  InvitationItem = Struct.new(:invitation, :other, :token, keyword_init: true)
  Duel = Struct.new(:id, :updated_at, keyword_init: true) do
    def to_param = id.to_s
  end
  DuelItem = Struct.new(:duel, :other, :state, :mine, :theirs, keyword_init: true)
  Person = Struct.new(:display_name, keyword_init: true)
  QuizReading = Struct.new(:study, :cite, :title, :artwork, :status, :progress_percent, keyword_init: true)
  WeeklyReading = Struct.new(
    :study, :cite, :title, :artwork, :status, :progress_percent, :study_unit_id,
    keyword_init: true
  )

  test "puts the earliest named invitation before one quiz-informed chapter" do
    later = invitation_item(id: 9, token: "later", name: "Maya", expires_at: 3.days.from_now)
    earliest = invitation_item(id: 4, token: "earliest", name: "Ana", expires_at: 1.day.from_now)
    recommendation = quiz_reading(study: "bofm/1-ne/5", cite: "1 Néphi 5:1")

    cards = Hubs::NowCards.call(
      campus: Campus.new(incoming: [ later, earliest ], active: []),
      reading_cards: [ recommendation, recommendation ],
      weekly_reading_cards: [ weekly_reading(study: "ot/ps/49", cite: "Psaumes 49", study_unit_id: 741) ]
    )

    assert_equal [ :challenge, :quiz_reading ], cards.map(&:kind)
    challenge, reading = cards
    assert_equal :incoming, challenge.state
    assert_equal "Ana", challenge.title
    assert_equal Rails.application.routes.url_helpers.street_challenge_accept_path("earliest"), challenge.path
    assert_equal :post, challenge.method
    assert_equal earliest.invitation.expires_at, challenge.due_at

    # A repeated upstream recommendation cannot turn the compact priority pile
    # into duplicate chapter cards; it always has exactly one reading slot.
    assert_equal recommendation.cite, reading.cite
    assert_equal recommendation.title, reading.title
    assert_equal :unread, reading.progress_status
    assert_equal Rails.application.routes.url_helpers.scripture_path(
      recommendation.study,
      cite: recommendation.cite
    ), reading.path
  end

  test "prefers a current turn over a ready duel and keeps waiting or results out of now" do
    current_turn = duel_item(
      id: 11,
      state: :your_turn,
      name: "Ingrid",
      updated_at: 2.hours.ago,
      mine: nil,
      theirs: 170
    )
    ready = duel_item(
      id: 12,
      state: :ready,
      name: "Lucas",
      updated_at: 1.minute.ago,
      mine: nil,
      theirs: nil
    )
    waiting = duel_item(
      id: 13,
      state: :waiting,
      name: "Carmen",
      updated_at: Time.current,
      mine: 210,
      theirs: nil
    )
    result = duel_item(
      id: 14,
      state: :resolved,
      name: "Pili",
      updated_at: Time.current,
      mine: 200,
      theirs: 180
    )

    cards = Hubs::NowCards.call(
      campus: Campus.new(incoming: [], active: [ ready, result, waiting, current_turn ]),
      reading_cards: [ quiz_reading(study: "ot/ps/49", cite: "Psaumes 49", status: :in_progress, progress_percent: 42) ],
      weekly_reading_cards: []
    )

    challenge, reading = cards
    assert_equal :your_turn, challenge.state
    assert_equal "Ingrid", challenge.title
    assert_equal Rails.application.routes.url_helpers.street_duel_path(11), challenge.path
    assert_equal :get, challenge.method
    assert_nil challenge.mine
    assert_equal 170, challenge.theirs
    assert_equal :quiz_reading, reading.kind
    assert_equal :in_progress, reading.progress_status
    assert_equal 42, reading.progress_percent
  end

  test "falls back to one published weekly chapter only when no quiz recommendation is available" do
    weekly = weekly_reading(study: "ot/ps/49", cite: "Psaumes 49-51", study_unit_id: 741, status: :unread, progress_percent: nil)

    cards = Hubs::NowCards.call(
      campus: Campus.new(incoming: [ invitation_item(id: 1, token: "hidden", name: "", expires_at: 1.hour.from_now) ], active: []),
      reading_cards: [],
      weekly_reading_cards: [ weekly, weekly_reading(study: "ot/ps/50", cite: "Psaumes 50", study_unit_id: 741) ]
    )

    assert_equal 1, cards.size
    card = cards.sole
    assert_equal :weekly_reading, card.kind
    assert_equal weekly.cite, card.cite
    assert_equal weekly.title, card.title
    assert_equal Rails.application.routes.url_helpers.scripture_path(
      weekly.study,
      cite: weekly.cite,
      study_unit_id: 741
    ), card.path
    assert_equal :unread, card.progress_status
    assert_nil card.progress_percent
  end

  test "skips chapters already completed instead of presenting them as priorities" do
    completed_quiz = quiz_reading(study: "bofm/1-ne/5", cite: "1 Néphi 5:1", status: :completed, progress_percent: 100)
    next_weekly = weekly_reading(study: "ot/ps/50", cite: "Psaumes 50", study_unit_id: 741, status: :unread, progress_percent: nil)

    cards = Hubs::NowCards.call(
      campus: Campus.new(incoming: [], active: []),
      reading_cards: [ completed_quiz ],
      weekly_reading_cards: [ weekly_reading(study: "ot/ps/49", cite: "Psaumes 49", study_unit_id: 741), next_weekly ]
    )

    assert_equal 1, cards.size
    assert_equal :weekly_reading, cards.sole.kind
    assert_equal next_weekly.cite, cards.sole.cite
    assert_equal :unread, cards.sole.progress_status
  end

  test "returns no priority card when all available data is non-actionable or anonymous" do
    cards = Hubs::NowCards.call(
      campus: Campus.new(
        incoming: [ invitation_item(id: 1, token: "anonymous", name: nil, expires_at: 1.hour.from_now) ],
        active: [ duel_item(id: 2, state: :waiting, name: "Maya", updated_at: Time.current, mine: 90, theirs: nil) ]
      ),
      reading_cards: [],
      weekly_reading_cards: []
    )

    assert_empty cards
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

    def quiz_reading(study:, cite:, status: :unread, progress_percent: nil)
      QuizReading.new(
        study:,
        cite:,
        title: "Titre éditorial",
        artwork: "media/study/psalms-refuge-2026.png",
        status:,
        progress_percent:
      )
    end

    def weekly_reading(study:, cite:, study_unit_id:, status: :completed, progress_percent: 100)
      WeeklyReading.new(
        study:,
        cite:,
        title: "Titre hebdomadaire",
        artwork: "media/study/psalms-refuge-2026.png",
        status:,
        progress_percent:,
        study_unit_id:
      )
    end
end
