require "test_helper"

class WardEventTest < ActiveSupport::TestCase
  setup do
    @ward = wards(:demo)
    @at = Time.zone.parse("2026-09-12 18:00:00")
  end

  test "requires the permitted kind, complete scheduling data, and one safe destination" do
    event = WardEvent.new({ ward: @ward }.merge(event_attributes(kind: "not_an_event", destination_path: nil, destination_url: nil)))

    assert_not event.valid?
    assert event.errors[:kind].present?
    assert_includes event.errors[:base], "requires exactly one destination"

    event.assign_attributes(kind: "food_drive", destination_path: "//outside.example", destination_url: nil)
    assert_not event.valid?
    assert event.errors[:destination_path].present?

    event.assign_attributes(destination_path: nil, destination_url: "http://outside.example")
    assert_not event.valid?
    assert event.errors[:destination_url].present?

    event.assign_attributes(destination_url: "https://example.org/collecte")
    assert event.valid?
    assert event.external_destination?

    event.assign_attributes(destination_url: nil, destination_path: "/ramas/RAMA")
    assert event.valid?

    event.assign_attributes(destination_path: "/s/DAVID/name")
    assert event.valid?

    event.assign_attributes(destination_path: "/ramas/NOPE")
    assert_not event.valid?
    assert event.errors[:destination_path].present?

    event.assign_attributes(destination_path: "/s/NOPE/name")
    assert_not event.valid?
    assert event.errors[:destination_path].present?

    event.assign_attributes(destination_path: "/not-a-real-event-destination")
    assert_not event.valid?
    assert event.errors[:destination_path].present?

    event.assign_attributes(artwork_path: "/media/not-an-editorial-artwork.jpg")
    assert_not event.valid?
    assert event.errors[:artwork_path].present?
  end

  test "requires explicit editorial approval before an event can be published" do
    event = WardEvent.new({ ward: @ward }.merge(event_attributes(status: "published")))

    assert_not event.valid?
    assert event.errors[:approved_by].present?
    assert event.errors[:approved_at].present?
  end

  test "keeps a transactional audit trail from draft through cancellation" do
    event = WardEvent.create_draft!(ward: @ward, attributes: event_attributes, actor: "Sœur Martin", at: @at)

    assert event.draft?
    assert_equal [ "created" ], event.ward_event_audits.pluck(:action)
    assert_equal "Sœur Martin", event.ward_event_audits.first.actor_label

    event.update_draft!(attributes: { title: "Collecte alimentaire du samedi" }, actor: "Sœur Martin", at: @at + 1.minute)
    assert_equal "Collecte alimentaire du samedi", event.title
    assert_equal %w[created updated], event.ward_event_audits.order(:created_at).pluck(:action)

    event.publish!(actor: "Présidence de Rama", at: @at + 2.minutes)
    assert event.published?
    assert_equal "Présidence de Rama", event.approved_by
    assert_equal @at + 2.minutes, event.approved_at
    assert_equal %w[created updated published], event.ward_event_audits.order(:created_at).pluck(:action)
    assert_raises(WardEvent::TransitionError) { event.update_draft!(attributes: { title: "Autre" }, actor: "Sœur Martin") }

    event.cancel!(actor: "Présidence de Rama", reason: "Le lieu n’est plus disponible", at: @at + 3.minutes)
    assert event.cancelled?
    assert_equal "Le lieu n’est plus disponible", event.cancellation_reason
    assert_equal %w[created updated published cancelled], event.ward_event_audits.order(:created_at).pluck(:action)
    assert_raises(WardEvent::TransitionError) { event.publish!(actor: "Présidence de Rama") }
  end

  test "does not treat expired or unapproved records as published feed entries" do
    draft = WardEvent.create_draft!(ward: @ward, attributes: event_attributes, actor: "Sœur Martin", at: @at)
    expired = WardEvent.create_draft!(
      ward: @ward,
      attributes: event_attributes(starts_at: @at - 3.hours, ends_at: @at - 1.hour, title: "Déjà terminée"),
      actor: "Sœur Martin",
      at: @at
    )
    expired.publish!(actor: "Présidence de Rama", at: @at)

    assert_not_includes WardEvent.visible_at(@at), draft
    assert_not_includes WardEvent.visible_at(@at), expired
  end

  test "never exposes a directly published record without its publication audit" do
    bypass = WardEvent.create!(
      { ward: @ward }.merge(
        event_attributes(
          title: "Publication sans audit",
          status: "published",
          approved_by: "Présidence de Rama",
          approved_at: @at
        )
      )
    )
    approved = WardEvent.create_draft!(ward: @ward, attributes: event_attributes(title: "Publication auditée"), actor: "Sœur Martin", at: @at)
    approved.publish!(actor: "Présidence de Rama", at: @at)

    assert bypass.published?
    assert_not_includes WardEvent.published, bypass
    assert_not_includes WardEvent.visible_at(@at), bypass
    assert_includes WardEvent.published, approved
    assert_includes WardEvent.visible_at(@at), approved
  end

  test "never exposes a directly cancelled record without both immutable approvals" do
    bypass = WardEvent.create!(
      { ward: @ward }.merge(
        event_attributes(
          title: "Annulation sans audit",
          status: "cancelled",
          approved_by: "Présidence de Rama",
          approved_at: @at,
          cancelled_by: "Présidence de Rama",
          cancelled_at: @at,
          cancellation_reason: "Fausse annulation"
        )
      )
    )
    approved = WardEvent.create_draft!(ward: @ward, attributes: event_attributes(title: "Annulation auditée"), actor: "Sœur Martin", at: @at)
    approved.publish!(actor: "Présidence de Rama", at: @at)
    approved.cancel!(actor: "Présidence de Rama", reason: "La salle est fermée", at: @at)

    assert bypass.cancelled?
    assert_not_includes WardEvent.cancelled_for_hub, bypass
    assert_not_includes WardEvent.visible_or_cancelled_at(@at), bypass
    assert_includes WardEvent.cancelled_for_hub, approved
    assert_includes WardEvent.visible_or_cancelled_at(@at), approved
  end

  private

    def event_attributes(overrides = {})
      {
        kind: "food_drive",
        title: "Collecte alimentaire",
        summary: "Apportez des produits non périssables.",
        starts_at: @at + 1.day,
        ends_at: @at + 1.day + 2.hours,
        location_label: "Salle paroissiale",
        destination_path: "/ramas/RAMA",
        artwork_path: "/media/church/worship.jpg"
      }.merge(overrides)
    end
end
