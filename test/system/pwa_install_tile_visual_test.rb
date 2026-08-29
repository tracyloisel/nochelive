require "application_system_test_case"

class PwaInstallTileVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots/temple-themed")

  test "install tile belongs to both celestial hub families" do
    catalog = Array(YAML.safe_load_file(Hubs::Backdrop::CATALOG)["backdrops"])
    worlds = {
      "celestial-light" => catalog.find { |row| row["id"] == "eden-lumiere" },
      "celestial-dark" => catalog.find { |row| row["id"] == "coronas-ungido" }
    }

    worlds.each do |theme, row|
      set_system_viewport(390, 844)
      Hubs::Backdrop.entries = [ row ]
      visit root_path
      assert_selector "body.is-#{theme}"

      page.execute_script("window.dispatchEvent(new Event('beforeinstallprompt', { cancelable: true }))")
      assert_selector ".hub-install", text: I18n.t("pwa.banner_title")
      assert_no_selector ".pwa-install-banner"

      FileUtils.mkdir_p(SHOT_DIR)
      { 390 => 844, 768 => 1024, 1440 => 900 }.each do |width, height|
        set_system_viewport(width, height)
        page.execute_script("document.querySelector('.street-hub-feed').scrollTop = 0")
        page.evaluate_async_script(<<~JS)
          var done = arguments[0];
          var images = Array.from(document.querySelectorAll('.hub-install img, .hub-hero img'));
          Promise.all(images.map(function(image) {
            if (image.decode) return image.decode().catch(function() {});
            if (image.complete) return Promise.resolve();
            return new Promise(function(resolve) {
              image.addEventListener('load', resolve, { once: true });
              image.addEventListener('error', resolve, { once: true });
            });
          })).then(done);
        JS

        assert page.evaluate_script(<<~JS), "install tile must lead the hub at #{width}px"
          (function() {
            var tile = document.querySelector('.hub-install').getBoundingClientRect();
            var hero = document.querySelector('.hub-hero').getBoundingClientRect();
            var viewport = document.documentElement.clientWidth;
            return tile.left >= -2 && tile.right <= viewport + 2 && tile.height >= 120 && tile.top < hero.top;
          })()
        JS

        suffix = width == 390 ? "" : "-#{width}"
        page.save_screenshot(SHOT_DIR.join("hub-install-#{theme}#{suffix}.png"))
      end

      set_system_viewport(390, 844)

      page.evaluate_async_script(<<~JS)
        var done = arguments[0];
        var controller = window.Stimulus.getControllerForElementAndIdentifier(document.body, "pwa-install");
        controller.openGuide({ currentTarget: document.querySelector(".hub-install") }).then(function() {
          document.querySelector(".pwa-install-browser-hint").hidden = true;
          done();
        }).catch(done);
      JS
      assert_selector ".pwa-install-dialog[open]"
      assert_selector ".pwa-install-done .picto-check", visible: true
      sleep 0.55

      guide = page.evaluate_script(<<~JS)
        (function() {
          var dialog = document.querySelector(".pwa-install-dialog");
          var emblem = dialog.querySelector(".pwa-install-emblem").getBoundingClientRect();
          var title = dialog.querySelector("#pwa_install_title").getBoundingClientRect();
          var done = dialog.querySelector(".pwa-install-done").getBoundingClientRect();
          var frame = dialog.getBoundingClientRect();
          return {
            scrollTop: dialog.scrollTop,
            scrollHeight: dialog.scrollHeight,
            clientHeight: dialog.clientHeight,
            emblemTop: emblem.top,
            titleTop: title.top,
            doneBottom: done.bottom,
            frameTop: frame.top,
            frameBottom: frame.bottom
          };
        })()
      JS
      assert_operator guide["scrollTop"], :<=, 1, "guide must always reopen at its beginning"
      assert_operator guide["emblemTop"], :>=, guide["frameTop"], "app emblem must be visible in the first frame"
      assert_operator guide["titleTop"], :>=, guide["frameTop"], "guide title must be visible in the first frame"
      assert_operator guide["doneBottom"], :<=, guide["frameBottom"] + 1, "completion action must stay visible"
      assert_operator guide["scrollHeight"], :<=, guide["clientHeight"] + 2, "iOS instructions must fit without tutorial scroll"
      assert page.evaluate_script("document.activeElement.classList.contains('pwa-install-sheet')"), "guide focus must start on its heading frame"
      page.save_screenshot(SHOT_DIR.join("ios-guide-#{theme}.png"))

      page.execute_script(<<~JS)
        window.Stimulus
          .getControllerForElementAndIdentifier(document.body, "pwa-install")
          .close();
      JS
      assert_no_selector ".pwa-install-dialog[open]"
      assert page.evaluate_script("document.activeElement.classList.contains('hub-install')"), "closing must return focus to the install tile"
      page.execute_script(<<~JS)
        window.NocheInstallPrompt = null;
        window.Stimulus
          .getControllerForElementAndIdentifier(document.body, "pwa-install")
          .hideInstallUi();
      JS
      assert_no_selector ".hub-install", visible: true
      assert_selector ".hub-install[hidden]", visible: :all
    end
  ensure
    Hubs::Backdrop.reset!
  end
end
