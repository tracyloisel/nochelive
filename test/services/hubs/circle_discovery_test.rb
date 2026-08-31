require "test_helper"

class Hubs::CircleDiscoveryTest < ActiveSupport::TestCase
  setup do
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @ward.scripture_circle_posts.delete_all
    @ward.scripture_circle_threads.delete_all
    @person = people(:pili)
    @author = people(:carmen_garcia)
  end

  test "returns a same-ward Circle doorway with a quiet activity state" do
    card = discover(theme: :light)

    assert_equal :active, card.state
    assert_equal Rails.application.routes.url_helpers.scripture_circle_path, card.path
    assert_equal "scripture_circle.backdrop.light", card.artwork
    assert_equal 0, card.activity.threads
    assert_equal 0, card.activity.replies
    assert_not card.activity.present?
  end

  test "summarizes only visible activity from active threads in the last seven days" do
    recent_root = create_post(body: "Une question récente", at: 2.days.ago)
    recent_reply = create_post(body: "Une réponse récente", kind: "reply", parent: recent_root, at: 1.day.ago)
    create_post(body: "Une ancienne question", at: 8.days.ago)
    hidden = create_post(body: "Un message masqué", at: 3.hours.ago)
    hidden.update!(status: "community_censored")
    archived = create_post(body: "Une discussion archivée", reference: "ot/ps/51", at: 2.hours.ago)
    archived.scripture_circle_thread.update!(status: "archived")

    card = discover

    assert_equal 1, card.activity.threads
    assert_equal 1, card.activity.replies
    assert_equal recent_reply.created_at.to_i, card.activity.last_at.to_i
    assert_predicate card.activity, :present?
  end

  test "keeps read-only Circle accessible and safely defaults an unknown theme to dark" do
    @ward.update!(scripture_circle_mode: "read_only")

    card = discover(theme: "celestial")

    assert_equal :read_only, card.state
    assert_equal "scripture_circle.backdrop.dark", card.artwork
  end

  test "fails closed for visitors, another ward, or a disabled Circle" do
    assert_nil Hubs::CircleDiscovery.call(person: nil, ward: @ward, theme: :dark)

    other_person = Struct.new(:ward_id).new(@ward.id + 1)
    assert_nil Hubs::CircleDiscovery.call(person: other_person, ward: @ward, theme: :dark)

    @ward.update!(scripture_circle_mode: "disabled")
    assert_nil discover
    assert_nil Hubs::CircleDiscovery.call(person: @person, ward: nil, theme: :dark)
  end

  private

    def discover(theme: :dark)
      Hubs::CircleDiscovery.call(person: @person, ward: @ward, theme:)
    end

    def create_post(body:, at:, kind: "question", parent: nil, reference: "ot/ps/52")
      thread = @ward.scripture_circle_threads.find_or_create_by!(reference:)
      travel_to(at) do
        thread.scripture_circle_posts.create!(
          ward: @ward,
          person: @author,
          kind:,
          parent:,
          locale: "fr",
          body:
        )
      end
    end
end
