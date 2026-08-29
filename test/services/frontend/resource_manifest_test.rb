require "test_helper"

class Frontend::ResourceManifestTest < ActiveSupport::TestCase
  test "serializes a bounded presentation-only manifest" do
    manifest = Frontend::ResourceManifest.new(
      context: "street.quiz.ask",
      styles: %w[shell street_play shell],
      controllers: %w[quiz countdown],
      media: { lcp: "quiz.exodus.red_sea" },
      audio: { unlock: true, cues: %w[round_open correct_gold] },
      prefetch: { nextScreen: true, maxBytes: 180_000 },
      classes: { "media.lcp" => "critical", "screen.next" => "predictive" }
    )

    assert_equal %w[shell street_play], manifest.styles
    assert_equal "quiz.exodus.red_sea", manifest.as_json.dig(:media, "lcp")
    assert_equal true, manifest.as_json.dig(:audio, "unlock")
    refute_includes manifest.to_json, "score"
  end

  test "rejects invalid context, classes and speculative bytes" do
    assert_raises(ArgumentError) { Frontend::ResourceManifest.new(context: "bad context") }
    assert_raises(ArgumentError) { Frontend::ResourceManifest.new(context: "hub", classes: { "x" => "eager" }) }
    assert_raises(ArgumentError) { Frontend::ResourceManifest.new(context: "hub", prefetch: { maxBytes: 180_001 }) }
  end
end
