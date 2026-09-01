require "test_helper"

class Hubs::RamaEventsTest < ActiveSupport::TestCase
  setup do
    @ward = wards(:demo)
    @other_ward = wards(:blank)
    @at = Time.zone.parse("2026-09-12 18:00:00")
  end

  test "returns only published local events in chronological order" do
    later = create_published_event(title: "Atelier musical", kind: "music_activity", starts_at: @at + 3.days)
    next_event = create_published_event(title: "Collecte alimentaire", starts_at: @at + 1.day)

    cards = Hubs::RamaEvents.call(ward: @ward, at: @at)

    assert_equal [ next_event.id, later.id ], cards.map(&:event_id)
    assert_equal [ "Collecte alimentaire", "Atelier musical" ], cards.map(&:title)
    assert_equal [ :food_drive, :music_activity ], cards.map(&:kind)
    assert cards.all? { |card| card.state == :published }
  end

  test "scopes events to the exact ward, keeps audited future cancellations honest, and excludes bypasses" do
    visible = create_published_event(title: "Activité sportive", kind: "sports_activity")
    create_published_event(ward: @other_ward, title: "Autre rama")
    create_draft_event(title: "Brouillon")
    cancelled = create_published_event(title: "Annulée")
    cancelled.cancel!(actor: "Présidence de Rama", reason: "La salle est fermée", at: @at)
    bypass = WardEvent.create!(
      ward: @ward,
      **event_attributes(
        title: "Annulation sans publication",
        status: "cancelled",
        approved_by: "Présidence de Rama",
        approved_at: @at,
        cancelled_by: "Présidence de Rama",
        cancelled_at: @at,
        cancellation_reason: "Faux historique"
      )
    )
    create_published_event(title: "Terminée", starts_at: @at - 4.hours, ends_at: @at - 1.hour)

    cards = Hubs::RamaEvents.call(ward: @ward, at: @at)

    assert_equal [ visible.id, cancelled.id ], cards.map(&:event_id)
    cancelled_card = cards.find { |card| card.event_id == cancelled.id }
    assert_equal :cancelled, cancelled_card.state
    assert_equal "La salle est fermée", cancelled_card.cancellation_reason
    assert_nil cancelled_card.path
    assert_not cancelled_card.external
    assert_not_includes cards.map(&:event_id), bypass.id
  end

  test "keeps validated destinations and identifies external links" do
    event = create_published_event(destination_path: nil, destination_url: "https://example.org/inscription")

    card = Hubs::RamaEvents.call(ward: @ward, at: @at).sole

    assert_equal event.destination_url, card.path
    assert card.external
    assert_equal event.artwork_path, card.still
    assert_equal :published, card.state
  end

  test "presents event times in the ward civil time zone" do
    @ward.update!(time_zone: "Europe/Madrid")
    utc_start = Time.utc(2026, 9, 13, 7, 30)
    event = create_published_event(starts_at: utc_start)

    card = Hubs::RamaEvents.call(ward: @ward, at: @at).sole

    assert_equal utc_start.to_i, card.starts_at.to_i
    assert_equal @ward.time_zone, card.starts_at.time_zone.name
    assert_equal 9, card.starts_at.hour
    assert_equal event.starts_at.to_i, card.starts_at.to_i
  end

  test "omits the block when there is no ward or no published local event" do
    assert_empty Hubs::RamaEvents.call(ward: nil, at: @at)
    assert_empty Hubs::RamaEvents.call(ward: @ward, at: @at)
  end

  private

    def create_draft_event(ward: @ward, **overrides)
      WardEvent.create_draft!(ward:, attributes: event_attributes(**overrides), actor: "Sœur Martin", at: @at)
    end

    def create_published_event(ward: @ward, **overrides)
      event = create_draft_event(ward:, **overrides)
      event.publish!(actor: "Présidence de Rama", at: @at)
      event
    end

    def event_attributes(**overrides)
      starts_at = overrides.delete(:starts_at) || @at + 1.day
      {
        kind: "food_drive",
        title: "Collecte alimentaire",
        summary: "Apportez des produits non périssables.",
        starts_at:,
        ends_at: overrides.delete(:ends_at) || starts_at + 2.hours,
        location_label: "Salle paroissiale",
        destination_path: "/ramas/RAMA",
        artwork_path: "/media/church/worship.jpg"
      }.merge(overrides)
    end
end
