require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  CHROME_CANDIDATES = [
    ENV["CHROME_BIN"],
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium-browser",
    "/usr/bin/chromium"
  ].compact.freeze

  def self.chrome_binary
    CHROME_CANDIDATES.find { |path| File.executable?(path) }
  end

  if chrome_binary
    Capybara.server = :puma, { Silent: true, Threads: "1:1" }

    driven_by :selenium, using: :headless_chrome, screen_size: [ 390, 844 ] do |options|
      options.binary = chrome_binary
      options.add_argument("--headless=new")
      options.add_argument("--disable-dev-shm-usage")
      options.add_argument("--no-sandbox")
      options.add_argument("--lang=es-ES")
      options.add_argument("--accept-lang=es-ES,es")
      options.add_preference("intl.accept_languages", "es-ES,es")
    end
  else
    driven_by :rack_test
  end

  setup do
    skip "Chrome is not available" unless self.class.chrome_binary
    Capybara.default_max_wait_time = 8
  end

  def join_night(code, name:, location: "room", team: nil, emblem: nil)
    visit night_name_path(code)
    assert_text "¿Cómo te llaman?"
    fill_in "¿Cómo te llaman en la rama?", with: name
    find("label.choice-chip", text: location == "remote" ? "En casa" : "En la sala").click
    click_button I18n.t("join.create_and_join")
    return if location == "remote"

    assert_text "Elige tu equipo"
    fill_in "Nombre del equipo", with: team
    find("label.emblem-choice", text: Team::EMBLEMS.fetch(emblem)).click
    click_button "Crear equipo"
  end
end
