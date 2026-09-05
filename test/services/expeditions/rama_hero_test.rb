require "test_helper"

module Expeditions
  class RamaHeroTest < ActiveSupport::TestCase
    ARTWORK_KEY = "expedition.psalms-102-150-fast.rama-weekly-hero"
    HEADLINES = {
      "es" => "Una pequeña llama puede cambiar toda una casa.",
      "pt-BR" => "Uma pequena chama pode mudar uma casa inteira.",
      "fr" => "Une petite flamme peut changer toute une maison.",
      "en" => "A small flame can change an entire home."
    }.freeze

    test "projects the Council-authored headline exactly in all four locales" do
      Locale::AVAILABLE.each do |locale|
        result = RamaHero.call(expedition: expedition, locale:)

        assert_equal HEADLINES.fetch(locale), result.headline
        assert_equal ARTWORK_KEY, result.artwork_key
        assert_equal "celestial_light", result.light_family
      end
    end

    test "does not fall back to Spanish for an unauthored locale" do
      assert_nil RamaHero.call(expedition: expedition, locale: :de)
    end

    test "requires a reviewed Council revision" do
      invalid = expedition.deep_dup
      invalid.fetch("rama_hero").delete("revision")

      assert_includes RamaHero.validation_errors(expedition: invalid),
        "rama_hero revision must be a positive integer"
    end

    test "requires exactly the four supported headlines" do
      missing = expedition.deep_dup
      missing.dig("rama_hero", "headline").delete("pt-BR")

      issues = RamaHero.validation_errors(expedition: missing)

      assert_includes issues, "rama_hero headline must contain exactly es, pt-BR, fr, en"
      assert_nil RamaHero.call(expedition: missing, locale: :es)
    end

    test "requires an artwork from the generated media manifest" do
      missing = expedition.deep_dup
      missing.fetch("rama_hero").delete("artwork_key")
      unknown = expedition.deep_dup
      unknown.fetch("rama_hero")["artwork_key"] = "expedition.missing.hero"

      assert_includes RamaHero.validation_errors(expedition: missing), "rama_hero artwork_key is required"
      assert_includes RamaHero.validation_errors(expedition: unknown),
        "rama_hero artwork_key must resolve in the media manifest"
    end

    test "requires a dedicated three-master Rama artwork and its reviewed digest" do
      borrowed = expedition.deep_dup
      borrowed.fetch("rama_hero")["artwork_key"] = "expedition.psalms-2026.home"
      borrowed.fetch("rama_hero")["artwork_digest"] = RamaHero.artwork_digest_for("expedition.psalms-2026.home")
      stale = expedition.deep_dup
      stale.fetch("rama_hero")["artwork_digest"] = "0" * 64

      assert_includes RamaHero.validation_errors(expedition: borrowed),
        "rama_hero artwork must use the rama_weekly_hero media role"
      assert_includes RamaHero.validation_errors(expedition: stale),
        "rama_hero artwork changed after Council review"
    end

    test "requires a supported light family" do
      invalid = expedition.deep_dup
      invalid.fetch("rama_hero")["light_family"] = "paper"

      assert_includes RamaHero.validation_errors(expedition: invalid),
        "rama_hero light_family must be celestial_light or celestial_dark"
    end

    private

      def expedition
        {
          "rama_hero" => {
            "revision" => 1,
            "headline" => HEADLINES,
            "artwork_key" => ARTWORK_KEY,
            "artwork_digest" => RamaHero.artwork_digest_for(ARTWORK_KEY),
            "light_family" => "celestial_light"
          }
        }
      end
  end
end
