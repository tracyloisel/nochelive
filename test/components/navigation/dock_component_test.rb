require "test_helper"
require "view_component/test_case"

class Navigation::DockComponentTest < ViewComponent::TestCase
  test "renders the five game destinations and marks the active one" do
    render_inline(Navigation::DockComponent.new(active: :profile))

    assert_selector "nav.navigation-dock"
    assert_selector "a.navigation-dock__item", count: 5
    assert_selector "a.navigation-dock__item.is-active", text: I18n.t("hub.nav_profile")
    assert_selector "a.navigation-dock__item.is-active[aria-current='page']", count: 1
    assert_selector "a.navigation-dock__item:not(.is-active)[aria-current]", count: 0
    assert_selector "svg.navigation-dock__icon", count: 5
    assert_selector ".navigation-dock__active-halo", count: 1
    assert_selector ".navigation-dock__active-rail", count: 1
    assert_selector "nav.navigation-dock[style='--dock-active-index: 4;']"
    assert_selector ".navigation-dock__icon .navigation-dock__icon-metal", minimum: 5
    assert_selector ".navigation-dock__icon .navigation-dock__icon-jewel", count: 5
    library = Rails.application.routes.url_helpers.scripture_library_path
    assert_selector "a.navigation-dock__item[href='#{library}'] > .picto-scripture-book"
    assert_no_selector ".street-hub-word-medallion"
  end

  test "marks the word destination active" do
    render_inline(Navigation::DockComponent.new(active: :word))

    assert_selector "a.navigation-dock__item.is-active[href='/bibliotheque'] > .picto-scripture-book"
  end

  test "moves the shared halo on the same five-column grid as the destinations" do
    %i[home adventure word church profile].each_with_index do |destination, index|
      render_inline(Navigation::DockComponent.new(active: destination))

      assert_selector "nav.navigation-dock[style='--dock-active-index: #{index};']"
    end

    css = Rails.root.join("app/assets/stylesheets/application.css").read
    halo_contract = css[/^\.navigation-dock__active-halo \{[^}]+\}/m]
    item_contract = css[/^\.navigation-dock__item \{[^}]+\}/m]
    assert_includes item_contract, "gap: 0.4rem;"
    assert_includes halo_contract, "top: 0.12rem;"
    assert_includes halo_contract, "height: 2.58rem;"
    assert_includes halo_contract, "left: var(--dock-side-padding);"
    assert_includes halo_contract, "width: calc((100% - (2 * var(--dock-side-padding))) / 5);"
    assert_includes halo_contract, "translateX(calc(var(--dock-active-index, 0) * 100%))"
    refute_includes css, "--dock-active-position"
    refute_match(/\.navigation-dock__item\.is-active > span\s*\{[^}]*transform:/m, css)
  end

  test "does not show an active rail when no destination is active" do
    render_inline(Navigation::DockComponent.new(active: nil))

    assert_selector "nav.navigation-dock:not(.has-active)"
  end

  test "owns the only global dock contract" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    layout = Rails.root.join("app/views/layouts/application.html.erb").read
    views = Rails.root.glob("app/views/**/*.erb").reject { |path| path.to_s.include?("layouts/application") }

    assert_equal 1, css.scan(/^\.navigation-dock \{/).size
    dock_contract = css[/^\.navigation-dock \{[^}]+\}/m]
    assert_includes dock_contract, "position: fixed;"
    assert_includes dock_contract, "left: max(0.75rem, env(safe-area-inset-left));"
    assert_includes dock_contract, "right: max(0.75rem, env(safe-area-inset-right));"
    assert_includes dock_contract, "bottom: max(0.62rem, env(safe-area-inset-bottom));"
    assert_includes dock_contract, "width: auto;"
    assert_includes dock_contract, "transform: none;"

    hud_contract = css[/^\.home-menu\.is-hud \{[^}]+\}/m]
    assert_includes hud_contract, "position: fixed;"
    assert_includes hud_contract, "left: 0;"
    assert_includes hud_contract, "right: 0;"
    assert_includes hud_contract, "width: auto;"
    assert_includes hud_contract, "max-width: none;"
    assert_includes hud_contract, "transform: none;"
    assert_includes hud_contract, "padding-inline: max(clamp(0.9rem, 3vw, 2.25rem), env(safe-area-inset-left));"
    assert_equal 1, css.scan(/^[^{\n]*\.home-menu\.is-hud\s*\{/).size

    hud_seam_contract = css[/^\.home-menu\.is-hud::before \{[^}]+\}/m]
    assert_includes hud_seam_contract, "inset: 0;"
    assert_includes hud_seam_contract, "box-shadow: inset 0 -1px 0"
    assert_includes css, ".home-menu.is-hud.is-compact::before { opacity: 0; }"

    hud_button_contract = css.scan(/^\.home-menu\.is-hud > \.home-menu-btn\.quiet-link \{[^}]+\}/m)
      .find { |contract| contract.include?("position: absolute;") }
    assert_includes hud_button_contract, "calc(clamp(0.9rem, 3vw, 2.25rem) + 0.4rem)"
    assert_includes css, "body > .home-menu.is-hud > .home-menu-btn.quiet-link"

    compact_contract = css[/^\.home-menu\.is-hud\.is-compact \{[^}]+\}/m]
    assert_includes compact_contract, "left: max(var(--hud-floating-inset), env(safe-area-inset-left));"
    assert_includes compact_contract, "right: max(var(--hud-floating-inset), env(safe-area-inset-right));"

    css.scan(/([^{}]+)\{([^{}]*)\}/m).each do |selector, declarations|
      next unless declarations.match?(/(?:^|;)\s*(?:position|top|right|bottom|left|inset|inset-inline|width|max-width|transform)\s*:/m)

      selector.split(",").map(&:strip).grep(/\.home-menu(?:\.[a-z0-9_-]+)*(?::(?:not|has)\([^)]*\))?\z/i).each do |menu_selector|
        next if [ ".home-menu.is-hud", ".home-menu.is-hud.is-compact" ].include?(menu_selector) || menu_selector.include?(":not(.is-hud)")

        flunk "#{menu_selector} must not override the shared HUD geometry"
      end
    end
    refute_includes css, "--navigation-dock-width"
    refute_includes css, "--hud-inset"
    assert_includes layout, "yield :hud"
    assert_includes layout, "yield :dock"
    views.each do |path|
      refute_includes path.read, "Navigation::DockComponent", "#{path} must use the layout dock slot"
      refute_includes path.read, "chrome_menu", "#{path} must use the layout HUD slot"
    end
    refute_includes css, ".street-hub-nav"
    refute_includes css, ".street-world-dock"
    refute_includes css, ".church-journey-nav"
    assert_includes css, "body.is-street-map-page .navigation-dock__item.is-adventure.is-active"
    assert_includes css, "body.is-study-run .navigation-dock"

    navigation_contract = css[/^  \.desktop-navigation a \{[^}]+\}/m]
    assert_includes navigation_contract, "text-shadow: var(--desktop-navigation-halo);"
    navigation_halo = css[/--desktop-navigation-halo:\s*([^;]+);/m, 1]
    refute_match(/(?:10|22|40)px/, navigation_halo)

    hub_css = Rails.root.join("app/assets/stylesheets/surfaces/hub.css").read
    assert_match(/@media \(min-width: 1200px\).*body\.is-street-hub\.is-game-hub-page \.street-world\.is-game-hub \{\s*--street-hub-dock-clearance: 0px;/m, hub_css)
  end
end
