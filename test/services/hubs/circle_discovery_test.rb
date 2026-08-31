require "test_helper"

class Hubs::CircleDiscoveryTest < ActiveSupport::TestCase
  PersonRef = Struct.new(:ward_id, keyword_init: true)
  WardWithoutPosts = Struct.new(:id, :scripture_circle_mode, :readable, keyword_init: true) do
    def scripture_circle_readable? = readable

    # The Hub card is only a door to the Circle. It must not query, count, or
    # serialize community posts to make a promotional preview.
    def scripture_circle_posts
      raise "CircleDiscovery must not inspect community posts"
    end
  end

  test "returns a same-ward active Circle doorway with the approved light artwork" do
    ward = WardWithoutPosts.new(id: 42, scripture_circle_mode: "active", readable: true)

    card = Hubs::CircleDiscovery.call(
      person: PersonRef.new(ward_id: 42),
      ward:,
      theme: :light
    )

    assert_equal :active, card.state
    assert_equal Rails.application.routes.url_helpers.scripture_circle_path, card.path
    assert_equal "scripture_circle.backdrop.light", card.artwork
  end

  test "keeps read-only Circle accessible and safely defaults an unknown theme to dark" do
    ward = WardWithoutPosts.new(id: 42, scripture_circle_mode: "read_only", readable: true)

    card = Hubs::CircleDiscovery.call(
      person: PersonRef.new(ward_id: 42),
      ward:,
      theme: "celestial"
    )

    assert_equal :read_only, card.state
    assert_equal "scripture_circle.backdrop.dark", card.artwork
  end

  test "fails closed for visitors, another ward, or a disabled Circle" do
    readable_ward = WardWithoutPosts.new(id: 42, scripture_circle_mode: "active", readable: true)
    disabled_ward = WardWithoutPosts.new(id: 42, scripture_circle_mode: "disabled", readable: false)

    assert_nil Hubs::CircleDiscovery.call(person: nil, ward: readable_ward, theme: :dark)
    assert_nil Hubs::CircleDiscovery.call(person: PersonRef.new(ward_id: 99), ward: readable_ward, theme: :dark)
    assert_nil Hubs::CircleDiscovery.call(person: PersonRef.new(ward_id: 42), ward: disabled_ward, theme: :dark)
    assert_nil Hubs::CircleDiscovery.call(person: PersonRef.new(ward_id: 42), ward: nil, theme: :dark)
  end

  test "does not perform database work or expose a post preview" do
    ward = WardWithoutPosts.new(id: 42, scripture_circle_mode: "active", readable: true)

    queries = sql_queries do
      card = Hubs::CircleDiscovery.call(
        person: PersonRef.new(ward_id: 42),
        ward:,
        theme: :dark
      )
      assert_equal "scripture_circle.backdrop.dark", card.artwork
    end
    assert_equal 0, queries
  end

  private

    def sql_queries(&block)
      count = 0
      callback = lambda do |_name, _start, _finish, _id, payload|
        count += 1 unless payload[:cached] || payload[:name].in?(%w[SCHEMA TRANSACTION])
      end
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
      count
    end
end
