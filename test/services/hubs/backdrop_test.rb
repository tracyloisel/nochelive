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

  test "theme_id override beats weekly rotation" do
    travel_to Time.zone.local(2026, 1, 5, 12) do
      weekly = Hubs::Backdrop.call
      picked = Hubs::Backdrop.call(theme_id: "reyes_y_profetas")
      assert_equal "dark", picked.theme.mode
      assert picked.theme.atmosphere.present?
      assert_equal "gold", picked.theme.accent
      refute_equal weekly.id, picked.id
    end
  end

  test "Bethlehem night artwork always selects celestial dark" do
    picked = Hubs::Backdrop.call(theme_id: "nazareno")

    assert_equal "nazareno-belen", picked.id
    assert_equal "dark", picked.theme.mode
    assert_match %r{\A/media/generated/hub/backdrop/nazareno-belen/.+\.webp\z}, picked.src
  end

  test "creation sky artwork always selects celestial dark" do
    creation_sky = Hubs::Backdrop.entries.find { |row| row["id"] == "moises-cielo" }
    Hubs::Backdrop.entries = [ creation_sky ]

    picked = Hubs::Backdrop.call

    assert_equal "moises-cielo", picked.id
    assert_equal "dark", picked.theme.mode
    assert_match %r{\A/media/generated/hub/backdrop/moises-cielo/.+\.webp\z}, picked.src
  end

  test "pack_id override matches tags" do
    picked = Hubs::Backdrop.call(pack_id: "moises", at: Time.zone.local(2026, 1, 5, 12))
    assert_match %r{\A/media/generated/hub/backdrop/}, picked.src
  end

  test "the active Light question selects the matching royal scene" do
    picked = Hubs::Backdrop.call(
      pack_id: "coronas",
      mode: "light"
    )

    assert_equal "royal-jerusalem-dawn", picked.id
    assert_equal "light", picked.theme.mode
    assert_equal "media/hub/light/royal-jerusalem-hero-v1.png", picked.hero
    assert_match %r{\A/media/generated/hub/backdrop/royal-jerusalem-dawn/}, picked.src
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
