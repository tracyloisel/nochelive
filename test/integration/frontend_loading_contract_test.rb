require "test_helper"

class FrontendLoadingContractTest < ActionDispatch::IntegrationTest
  test "hub declares a validated presentation manifest and one contextual Campus sheet" do
    get root_path, headers: { "HTTP_ACCEPT" => "text/html,image/webp" }

    assert_response :success
    assert_select "script#noche_resource_manifest[type='application/json']", count: 1
    manifest = JSON.parse(css_select("#noche_resource_manifest").first.text)
    assert_equal "hub.home", manifest.fetch("context")
    assert_equal %w[shell hub onboarding study], manifest.fetch("styles")
    assert_equal "critical", manifest.fetch("classes").fetch("media.lcp")
    assert_includes manifest.fetch("controllers"), "hub-campus"
    assert_equal "viewport", manifest.fetch("classes").fetch("controller.hub_campus")
    assert_includes manifest.fetch("motion"), "list-enter"
    assert_equal 180_000, manifest.dig("prefetch", "maxBytes")
    refute manifest.key?("score")

    assert_select "link[href*='surfaces/hub'][data-turbo-track='dynamic']", count: 1
    assert_select "link[href*='surfaces/study'][data-turbo-track='dynamic']", count: 1
    assert_select "link[href*='duel_campus']", count: 0
    assert_select "link[href*='shell/loading'][data-turbo-track='reload']", count: 1
    assert_select "[data-controller~='loading'] .noche-loading[data-loading-target='indicator']", count: 1
    assert_select "body[data-controller~='stage']", count: 1
    assert_select "body[data-controller~='scripture']", count: 0
    assert_select "body[data-controller~='scripture-launcher']", count: 1
    assert_select "script#noche_sfx_catalog[type='application/json']", count: 1
    catalog_script = css_select("script#noche_sfx_catalog").first.text
    assert_includes catalog_script, "celestial_breath"
    refute_includes catalog_script, "timer_tension"
    assert_select "link[rel='preload'][as='image'][imagesrcset*='390w'][imagesrcset*='941w']", count: 1
    assert_select "picture.street-world-art-picture source[type='image/avif'][srcset*='390w']", count: 1
    assert_select "picture.street-world-art-picture source[type='image/avif'][media='(min-width: 768px)'][srcset*='landscape']", count: 1
    assert_select "picture.street-world-art-picture img.street-world-art[width][height][fetchpriority='high']", count: 1
  end

  test "non Campus surface does not receive the Campus stylesheet" do
    get legal_path

    assert_response :success
    assert_select "link[href*='duel_campus']", count: 0
    assert_select "body[data-controller~='stage']", count: 0
    assert_select "script#noche_sfx_catalog", count: 0
    assert_select "#noche_sfx_gate", count: 0
    manifest = JSON.parse(css_select("#noche_resource_manifest").first.text)
    assert_equal "shell", manifest.fetch("context")
  end

  test "scripture loading has a reader-specific progressive and accessible threshold" do
    get root_path

    assert_response :success
    assert_select "#scripture_loading.reader-loading-veil[data-scripture-launcher-target='loading'][data-state='idle'][hidden]", count: 1
    assert_select "#scripture_loading[role='status'][aria-live='polite'][aria-busy='true'][data-reader-loading-chapter-fallback]", count: 1
    assert_select "#scripture_loading picture.reader-loading-art-image-picture img[width][height][loading='lazy'][fetchpriority='low']", count: 1
    assert_select "#scripture_loading .reader-loading-copy", count: 4
    assert_select "#scripture_loading [data-reader-loading-chapter]", count: 1
    assert_select "#scripture_loading [data-reader-loading-template]", count: 4
    assert_select "#scripture_loading [data-reader-loading-retry][data-action='scripture-launcher#retry']", count: 1
    assert_select "#scripture_loading .reader-loading-dismiss[data-action='scripture-launcher#cancel'][aria-label=?]", I18n.t("scripture_reader.close")

    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        assert I18n.t("scripture_reader.close").present?
        assert I18n.t("scripture_reader.loading.opening", chapter: "Psaume 52").include?("Psaume 52")
        assert I18n.t("scripture_reader.loading.slow", chapter: "Psaume 52").include?("Psaume 52")
        assert I18n.t("scripture_reader.loading.waiting", chapter: "Psaume 52").include?("Psaume 52")
        assert I18n.t("scripture_reader.loading.failed", chapter: "Psaume 52").include?("Psaume 52")
        assert I18n.t("scripture_reader.loading.retry").present?
      end
    end

    css = Rails.root.join("app/assets/stylesheets/shell/loading.css").read
    assert_includes css, 'html.is-scripture-open .noche-loading'
    assert_includes css, '.reader-loading-veil[data-state="failed"]'
    assert_match(/prefers-reduced-motion: reduce[\s\S]*\.reader-loading-beacon i/m, css)
  end

  test "street play declares current predictive and audio resources without dead motion recipes" do
    start_street_jugar!

    manifest = JSON.parse(css_select("#noche_resource_manifest").first.text)
    assert_equal "street.quiz.ask", manifest.fetch("context")
    assert_equal "critical", manifest.fetch("classes").fetch("media.lcp")
    assert_equal "predictive", manifest.fetch("classes").fetch("media.next")
    assert_equal true, manifest.dig("audio", "unlock")
    assert_equal "timer_tension", manifest.dig("audio", "bed")
    assert_includes manifest.dig("audio", "cues"), "fire_whoosh"
    refute_includes manifest.dig("audio", "cues"), "dramatic_fire"
    assert_empty manifest.fetch("motion")
  end

  test "service worker renders the digest-aware offline shell asset" do
    get pwa_service_worker_path(format: :js)

    assert_response :success
    refute_includes response.body, "<%="
    assert_match %r{/assets/shell/loading(?:-[a-f0-9]+)?\.css}, response.body
  end
end
