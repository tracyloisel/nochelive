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

  test "large raster artwork has a compact webp delivery path" do
    originals = Rails.root.glob("public/media/**/*.{jpg,jpeg,png}")
      .select { |path| path.size > 150.kilobytes }
    variants = originals.map { |path| path.sub_ext(".webp") }

    missing = variants.reject(&:file?)
    assert_empty missing, "missing WebP variants: #{missing.take(5).join(', ')}"

    original_bytes = originals.sum(&:size)
    variant_bytes = variants.sum(&:size)
    assert_operator variant_bytes, :<, original_bytes * 0.35,
      "WebP variants must keep the heavy-media transfer budget below 35% of originals"
  end

  test "the hidden install guide does not eagerly create its screenshots" do
    layout = Rails.root.join("app/views/layouts/application.html.erb").read

    assert_includes layout, '<template data-pwa-install-target="guideTemplate">'
    assert_equal 4, layout.scan(/pwa-install-step-art" loading="lazy" decoding="async"/).size
  end
end
