require "test_helper"

class Hubs::ExploreCardsTest < ActiveSupport::TestCase
  Card = Struct.new(
    :study, :cite, :title, :artwork, :status, :progress_percent,
    :study_unit_id,
    keyword_init: true
  )

  test "keeps one real route per chapter and prioritizes unfinished quiz readings" do
    quiz = card(
      study: "ot/ps/23",
      cite: "Psaumes 23",
      title: "Psaumes 23",
      status: :unread
    )
    duplicate_weekly = card(
      study: "ot/ps/23",
      cite: "Le Seigneur est mon berger",
      title: "Psaumes 23",
      status: :completed,
      study_unit_id: 42
    )
    underway = card(
      study: "ot/ps/27",
      cite: "Psaumes 27",
      title: "Psaumes 27",
      status: :in_progress,
      progress_percent: 38,
      study_unit_id: 42
    )

    result = Hubs::ExploreCards.call(
      reading_cards: [ quiz ],
      weekly_reading_cards: [ duplicate_weekly, underway ]
    )

    assert_equal %w[ot/ps/27 ot/ps/23], result.map(&:study)
    assert_equal %i[weekly quiz], result.map(&:source)
    assert_equal 38, result.first.progress_percent
    assert_equal Rails.application.routes.url_helpers.scripture_path(
      "ot/ps/27",
      cite: "Psaumes 27",
      study_unit_id: 42
    ), result.first.path
    assert_equal 1, result.count { |entry| entry.study == "ot/ps/23" }
  end

  test "omits malformed entries and honors the bounded Home rail" do
    cards = 10.times.map do |index|
      card(
        study: "ot/ps/#{index + 1}",
        cite: "Psaumes #{index + 1}",
        title: "Psaumes #{index + 1}",
        status: :unread
      )
    end
    cards.unshift(card(study: nil, title: "Sans route", status: :unread))

    result = Hubs::ExploreCards.call(
      reading_cards: cards,
      weekly_reading_cards: [],
      limit: 4
    )

    assert_equal 4, result.size
    assert result.all? { |entry| entry.path.include?(entry.study) }
  end

  test "excludes the chapter already selected for Today" do
    today = card(study: "ot/ps/23", cite: "Psaumes 23", title: "Psaumes 23", status: :unread)
    next_reading = card(study: "ot/ps/27", cite: "Psaumes 27", title: "Psaumes 27", status: :unread)

    result = Hubs::ExploreCards.call(
      reading_cards: [ today, next_reading ],
      weekly_reading_cards: [ today ],
      exclude_studies: [ today.study ]
    )

    assert_equal [ "ot/ps/27" ], result.map(&:study)
  end

  private

    def card(**attributes)
      Card.new(**attributes)
    end
end
