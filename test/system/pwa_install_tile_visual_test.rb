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
      page.execute_script(<<~JS)
        localStorage.removeItem("noche:pwa-install-dismissed-at");
        localStorage.removeItem("noche:pwa-install-ios-guide-seen-at");
        localStorage.removeItem("noche:pwa-install-installed-at");
        localStorage.removeItem("noche:pwa-install-rejected-at");
        sessionStorage.removeItem("noche:pwa-install-offered");
      JS
      assert_selector "body.is-#{theme}"

      dispatch_install_prompt
      assert_selector ".hub-install", text: I18n.t("pwa.banner_title")
      assert_selector ".hub-install.hub-install--compact"
      assert_no_selector ".pwa-install-banner"

      assert page.evaluate_script(<<~JS), "install stays a compact utility immediately after the Rama carousel and before follow-up cards"
        (function() {
          var feed = document.querySelector(".hub-streaming-feed--editorial");
          var install = feed && feed.querySelector(".hub-install--compact");
          var carousel = feed && feed.querySelector(".hub-rama-carousel");
          if (!feed || !install) return false;

          var children = Array.from(feed.children);
          var installIndex = children.indexOf(install);
          var beforeInstall = function(selector) {
            var node = feed.querySelector(selector);
            return !node || children.indexOf(node) < installIndex;
          };
          var afterInstall = function(selector) {
            var node = feed.querySelector(selector);
            return !node || children.indexOf(node) > installIndex;
          };

          return Boolean(carousel) &&
            beforeInstall(".hub-hero") &&
            beforeInstall(".hub-rama-carousel") &&
            carousel.nextElementSibling === install &&
            afterInstall(".hub-now");
        })()
      JS

      FileUtils.mkdir_p(SHOT_DIR)
      { 390 => 844, 768 => 1024, 1440 => 900 }.each do |width, height|
        set_system_viewport(width, height)
        page.execute_script("document.querySelector('.street-hub-feed').scrollTop = 0")
        page.evaluate_async_script(<<~JS)
          var done = arguments[0];
          var images = Array.from(document.querySelectorAll('.hub-install img, .hub-hero img'));
          var decoded = Promise.all(images.map(function(image) {
            if (image.decode) return image.decode().catch(function() {});
            if (image.complete) return Promise.resolve();
            return new Promise(function(resolve) {
              image.addEventListener('load', resolve, { once: true });
              image.addEventListener('error', resolve, { once: true });
            });
          }));
          Promise.race([
            decoded,
            new Promise(function(resolve) { setTimeout(resolve, 3000); })
          ]).then(done);
        JS

        assert page.evaluate_script(<<~JS), "install tile must stay inside the hub and below the Rama carousel at #{width}px"
          (function() {
            var tile = document.querySelector('.hub-install').getBoundingClientRect();
            var carouselNode = document.querySelector('.hub-rama-carousel');
            var carousel = carouselNode.getBoundingClientRect();
            var action = document.querySelector('.hub-install-action').getBoundingClientRect();
            var dismiss = document.querySelector('.hub-install-dismiss').getBoundingClientRect();
            var viewport = document.documentElement.clientWidth;
            return carouselNode.nextElementSibling === document.querySelector('.hub-install') &&
              tile.top >= carousel.bottom - 1 &&
              tile.left >= -2 && tile.right <= viewport + 2 &&
              tile.height >= 44 &&
              action.width >= 44 && action.height >= 44 &&
              dismiss.width >= 44 && dismiss.height >= 44;
          })()
        JS

        page.execute_script(<<~JS)
          document.querySelector('.hub-install').scrollIntoView({ block: 'center', inline: 'nearest' });
        JS
        assert page.evaluate_script(<<~JS), "install tile must be inspectable without being hidden behind hub chrome at #{width}px"
          (function() {
            var tile = document.querySelector('.hub-install').getBoundingClientRect();
            return tile.top >= 0 && tile.bottom <= window.innerHeight;
          })()
        JS

        suffix = width == 390 ? "" : "-#{width}"
        page.save_screenshot(SHOT_DIR.join("hub-install-#{theme}#{suffix}.png"))
      end

      set_system_viewport(390, 844)

      page.evaluate_async_script(<<~JS)
        var done = arguments[0];
        var controller = window.Stimulus.getControllerForElementAndIdentifier(document.body, "pwa-install");
        controller.isIos = function() { return true; };
        controller.openGuide({ currentTarget: document.querySelector(".hub-install-action") }).then(function() {
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
      assert page.evaluate_script("document.activeElement.classList.contains('hub-install-action')"), "closing must return focus to the install action"
      page.evaluate_async_script(<<~JS)
        var done = arguments[0];
        window.Stimulus
          .getControllerForElementAndIdentifier(document.body, "pwa-install")
          .openGuide({ currentTarget: document.querySelector(".hub-install-action") })
          .then(done)
          .catch(done);
      JS
      assert_selector ".pwa-install-dialog[open]"
      page.execute_script(<<~JS)
        window.Stimulus
          .getControllerForElementAndIdentifier(document.body, "pwa-install")
          .close();
      JS
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

  test "tile only appears for a usable browser offer and remembers dismissals and refusals" do
    set_system_viewport(390, 844)
    visit root_path
    unsupported = page.evaluate_script(<<~JS)
      (function() {
        localStorage.removeItem("noche:pwa-install-dismissed-at");
        localStorage.removeItem("noche:pwa-install-ios-guide-seen-at");
        localStorage.removeItem("noche:pwa-install-installed-at");
        localStorage.removeItem("noche:pwa-install-rejected-at");
        sessionStorage.removeItem("noche:pwa-install-offered");
        window.NocheInstallPrompt = null;

        var controller = window.Stimulus.getControllerForElementAndIdentifier(document.body, "pwa-install");
        controller.clearDeferredPrompt();
        controller.syncInstallOffer();
        return {
          deferredPrompt: Boolean(controller.deferredPrompt),
          ios: controller.isIos(),
          standalone: controller.isStandalone(),
          canOffer: controller.canOfferInstall(),
          tileHidden: document.querySelector(".hub-install").hidden
        };
      })()
    JS

    refute unsupported.fetch("deferredPrompt"), unsupported.inspect
    refute unsupported.fetch("ios"), unsupported.inspect
    refute unsupported.fetch("standalone"), unsupported.inspect
    refute unsupported.fetch("canOffer"), unsupported.inspect
    assert unsupported.fetch("tileHidden"), unsupported.inspect
    assert_selector ".hub-install[hidden]", visible: :all

    dispatch_install_prompt
    assert_selector ".hub-install", visible: true
    find(".hub-install-dismiss").click
    assert_selector ".hub-install[hidden]", visible: :all
    assert page.evaluate_script("Boolean(localStorage.getItem('noche:pwa-install-dismissed-at'))")

    dispatch_install_prompt
    assert_selector ".hub-install[hidden]", visible: :all

    page.execute_script("localStorage.removeItem('noche:pwa-install-dismissed-at')")
    dispatch_install_prompt(outcome: "dismissed")
    assert_selector ".hub-install", visible: true
    find(".hub-install-action").click
    assert_selector ".hub-install[hidden]", visible: :all
    assert page.evaluate_script("Boolean(localStorage.getItem('noche:pwa-install-rejected-at'))")

    page.execute_script("localStorage.removeItem('noche:pwa-install-rejected-at')")
    dispatch_install_prompt(outcome: "accepted")
    find(".hub-install-action").click
    assert_selector ".hub-install[data-pwa-install-state='awaiting_confirmation'][aria-busy='false']", visible: true
    assert_selector ".hub-install-status[role='status'][aria-live='polite']", text: I18n.t("pwa.installing"), visible: true
    assert page.evaluate_script("document.querySelector('.hub-install-action').disabled"), "the one-use browser prompt must not be offered twice"
    refute page.evaluate_script("Boolean(localStorage.getItem('noche:pwa-install-installed-at'))"), "accepting the browser prompt is not proof of installation"

    dispatch_install_prompt
    assert_selector ".hub-install[data-pwa-install-state='ready'][aria-busy='false']", visible: true
    refute page.evaluate_script("document.querySelector('.hub-install-action').disabled"), "a fresh browser offer is an honest retry path"

    page.execute_script("window.dispatchEvent(new Event('appinstalled'))")
    assert_selector ".hub-install[hidden]", visible: :all
    assert page.evaluate_script("Boolean(localStorage.getItem('noche:pwa-install-installed-at'))")
  end

  test "iOS guidance honors an explicit dismissal and a guide already seen" do
    set_system_viewport(390, 844)
    visit root_path
    page.execute_script(<<~JS)
      localStorage.removeItem("noche:pwa-install-dismissed-at");
      localStorage.removeItem("noche:pwa-install-ios-guide-seen-at");
      localStorage.removeItem("noche:pwa-install-installed-at");
      localStorage.removeItem("noche:pwa-install-rejected-at");
      sessionStorage.removeItem("noche:pwa-install-offered");
      var controller = window.Stimulus.getControllerForElementAndIdentifier(document.body, "pwa-install");
      controller.isIos = function() { return true; };
      controller.clearDeferredPrompt();
      controller.showAction();
    JS

    assert_selector ".hub-install", visible: true
    find(".hub-install-dismiss").click
    assert_selector ".hub-install[hidden]", visible: :all
    assert page.evaluate_script("Boolean(localStorage.getItem('noche:pwa-install-dismissed-at'))")

    page.execute_script(<<~JS)
      localStorage.removeItem("noche:pwa-install-dismissed-at");
      var controller = window.Stimulus.getControllerForElementAndIdentifier(document.body, "pwa-install");
      controller.showAction();
    JS
    assert_selector ".hub-install", visible: true

    page.evaluate_async_script(<<~JS)
      var done = arguments[0];
      var controller = window.Stimulus.getControllerForElementAndIdentifier(document.body, "pwa-install");
      controller.openGuide({ currentTarget: document.querySelector(".hub-install-action") }).then(done).catch(done);
    JS
    assert_selector ".pwa-install-dialog[open]"
    page.execute_script("window.Stimulus.getControllerForElementAndIdentifier(document.body, 'pwa-install').close()")
    assert page.evaluate_script("Boolean(localStorage.getItem('noche:pwa-install-ios-guide-seen-at'))")

    page.execute_script(<<~JS)
      var controller = window.Stimulus.getControllerForElementAndIdentifier(document.body, "pwa-install");
      controller.showAction();
    JS
    assert_selector ".hub-install[hidden]", visible: :all

    page.execute_script(<<~JS)
      localStorage.removeItem("noche:pwa-install-ios-guide-seen-at");
      var controller = window.Stimulus.getControllerForElementAndIdentifier(document.body, "pwa-install");
      controller.showAction();
    JS
    assert_selector ".hub-install[hidden]", visible: :all
  end

  private

    def dispatch_install_prompt(outcome: nil)
      choice = outcome ? "Promise.resolve({ outcome: #{outcome.to_json} })" : "new Promise(function() {})"
      page.execute_script(<<~JS)
        (function() {
          var event = new Event("beforeinstallprompt", { cancelable: true });
          Object.defineProperties(event, {
            prompt: { value: function() { return Promise.resolve(); } },
            userChoice: { value: #{choice} }
          });
          window.dispatchEvent(event);
        })();
      JS
    end
end
