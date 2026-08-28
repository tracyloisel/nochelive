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
    assert_selector ".navigation-dock__icon .navigation-dock__icon-metal", minimum: 5
    assert_selector ".navigation-dock__icon .navigation-dock__icon-jewel", count: 5
    parole = Rails.application.routes.url_helpers.study_program_path
    assert_selector "a.navigation-dock__item[href='#{parole}'] > .picto-scripture-book"
    assert_no_selector ".street-hub-word-medallion"
  end

  test "marks the word destination active" do
    render_inline(Navigation::DockComponent.new(active: :word))

    assert_selector "a.navigation-dock__item.is-active[href='/parole'] > .picto-scripture-book"
  end

  test "owns the only global dock contract" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    layout = Rails.root.join("app/views/layouts/application.html.erb").read
    views = Rails.root.glob("app/views/**/*.erb").reject { |path| path.to_s.include?("layouts/application") }

    assert_equal 1, css.scan(/^\.navigation-dock \{/).size
    dock_contract = css[/^\.navigation-dock \{[^}]+\}/m]
    assert_includes dock_contract, "position: fixed;"
    assert_includes dock_contract, "left: 0;"
    assert_includes dock_contract, "right: 0;"
    assert_includes dock_contract, "bottom: 0;"
    assert_includes dock_contract, "width: auto;"
    assert_includes dock_contract, "transform: none;"

    hud_contract = css[/^\.home-menu\.is-hud \{[^}]+\}/m]
    assert_includes hud_contract, "position: fixed;"
    assert_includes hud_contract, "left: env(safe-area-inset-left);"
    assert_includes hud_contract, "right: env(safe-area-inset-right);"
    assert_includes hud_contract, "width: auto;"
    assert_includes hud_contract, "max-width: none;"
    assert_includes hud_contract, "transform: none;"
    assert_equal 1, css.scan(/^[^{\n]*\.home-menu\.is-hud\s*\{/).size

    css.scan(/([^{}]+)\{([^{}]*)\}/m).each do |selector, declarations|
      next unless declarations.match?(/(?:^|;)\s*(?:position|top|right|bottom|left|inset|inset-inline|width|max-width|transform)\s*:/m)

      selector.split(",").map(&:strip).grep(/\.home-menu(?:\.[a-z0-9_-]+)*(?::(?:not|has)\([^)]*\))?\z/i).each do |menu_selector|
        next if menu_selector == ".home-menu.is-hud" || menu_selector.include?(":not(.is-hud)")

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
  end
end
