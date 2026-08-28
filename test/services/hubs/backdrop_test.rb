require "test_helper"

class Hubs::BackdropTest < ActiveSupport::TestCase
  setup { Hubs::Backdrop.reset! }
  teardown { Hubs::Backdrop.reset! }

  test "weekly rotation is ISO week modulo the catalog" do
    list = Hubs::Backdrop.entries
    travel_to Time.zone.local(2026, 1, 5, 12) do
      picked = Hubs::Backdrop.call
      week = Date.new(2026, 1, 5).cweek
      expected = list[(week - 1) % list.size]
      assert_equal expected["id"], picked.id
    end
  end

  test "random rotation picks a dedicated home backdrop and avoids the previous one" do
    list = Hubs::Backdrop.entries
    previous = list.first
    picked = Hubs::Backdrop.call(
      randomize: true,
      exclude_id: previous["id"],
      random: Random.new(1234)
    )

    assert_includes list.drop(1).map { |row| row["id"] }, picked.id
    refute_equal previous["id"], picked.id
    assert_match %r{\A/media/home/}, picked.src
    assert_includes %w[light dark], picked.theme.mode
  end

  test "random rotation still works with a one-entry catalog" do
    only = Hubs::Backdrop.entries.first
    Hubs::Backdrop.entries = [ only ]

    picked = Hubs::Backdrop.call(randomize: true, exclude_id: only["id"])

    assert_equal only["id"], picked.id
  end

  test "theme_id override beats weekly rotation" do
    travel_to Time.zone.local(2026, 1, 5, 12) do
      weekly = Hubs::Backdrop.call
      picked = Hubs::Backdrop.call(theme_id: "reyes_y_profetas")
      assert_includes picked.tags, "reyes_y_profetas"
      assert_equal "dark", picked.theme.mode
      assert picked.theme.atmosphere.present?
      assert_equal "gold", picked.theme.accent
      refute_equal weekly.id, picked.id unless weekly.tags.include?("reyes_y_profetas")
    end
  end

  test "tagged returns nil when no catalog row matches" do
    assert_nil Hubs::Backdrop.tagged(theme_id: "no-such-world")
    assert_nil Hubs::Backdrop.tagged(theme_id: nil)
  end

  test "tagged matches kings_and_prophets to the Reyes still" do
    picked = Hubs::Backdrop.tagged(theme_id: "kings_and_prophets")
    assert_equal "coronas-ungido", picked.id
    assert_equal "dark", picked.theme.mode
    assert_match %r{/media/home/coronas-reino\.jpg\z}, picked.src
  end

  test "Bethlehem night artwork always selects celestial dark" do
    picked = Hubs::Backdrop.call(theme_id: "nazareno")

    assert_equal "nazareno-belen", picked.id
    assert_equal "dark", picked.theme.mode
    assert_match %r{/media/home/nazareno-belen\.jpg\z}, picked.src
  end

  test "pack_id override matches tags" do
    picked = Hubs::Backdrop.call(pack_id: "moises", at: Time.zone.local(2026, 1, 5, 12))
    assert_includes picked.tags, "moises"
    assert_match %r{\A/media/home/}, picked.src
  end

  test "missing image falls back to the marble hall" do
    Hubs::Backdrop.entries = [ { "id" => "ghost", "image" => "missing/nope.jpg", "tags" => [], "theme" => { "mode" => "dark" } } ]
    picked = Hubs::Backdrop.call(at: Time.zone.local(2026, 1, 5, 12))
    assert_equal Hubs::Backdrop::FALLBACK_SRC, picked.src
    assert_equal "dark", picked.theme.mode
  end

  test "invalid mode falls back to light" do
    Hubs::Backdrop.entries = [ { "id" => "odd", "image" => "home/moises-mer-rouge.jpg", "theme" => { "mode" => "neon" } } ]
    picked = Hubs::Backdrop.call
    assert_equal "light", picked.theme.mode
  end
end
