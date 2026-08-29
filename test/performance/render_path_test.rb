require "test_helper"

class RenderPathTest < ActiveSupport::TestCase
  test "stimulus controllers stay out of the global preload graph" do
    imports = Rails.root.join("config/importmap.rb").read
    loader = Rails.root.join("app/javascript/controllers/index.js").read

    assert_includes imports, 'pin_all_from "app/javascript/controllers", under: "controllers", preload: false'
    assert_includes imports, 'pin "haptics", to: "haptics.js", preload: false'
    assert_includes loader, "lazyLoadControllersFrom"
    refute_includes loader, "eagerLoadControllersFrom"
  end

  test "large raster masters stay private and have compact mobile delivery" do
    masters = Rails.root.glob("media/masters/**/*.{jpg,jpeg,png,webp}")
      .select { |path| path.size > 150.kilobytes }
    manifest = JSON.parse(Rails.root.join("config/media/generated_manifest.json").read)
    mobile_bytes = manifest.fetch("assets").values.sum do |asset|
      asset.dig("variants", "avif").min_by { |variant| variant.fetch("width") }.fetch("bytes")
    end

    assert_operator masters.size, :>=, 400
    assert_empty Rails.root.glob("public/media/**/*.{jpg,jpeg,png}").reject { |path| path.to_s.include?("/generated/") }
    assert_operator mobile_bytes, :<, masters.sum(&:size) * 0.2,
      "one mobile AVIF per asset must stay below 20% of the source catalog"
  end

  test "the hidden install guide does not eagerly create its screenshots" do
    layout = Rails.root.join("app/views/layouts/application.html.erb").read

    assert_includes layout, '<template data-pwa-install-target="guideTemplate">'
    assert_equal 4, layout.scan(/pwa-install-step-art/).size
  end
end
