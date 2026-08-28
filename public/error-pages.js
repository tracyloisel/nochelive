(function () {
  "use strict";

  var locales = ["es", "pt-BR", "fr", "en"];
  var localeNames = {
    es: "Español",
    "pt-BR": "Português",
    fr: "Français",
    en: "English"
  };

  function normalize(value) {
    var raw = String(value || "").replace("_", "-").toLowerCase();
    if (raw.indexOf("pt") === 0) return "pt-BR";
    if (raw.indexOf("fr") === 0) return "fr";
    if (raw.indexOf("en") === 0) return "en";
    return "es";
  }

  function queryLocale() {
    var match = window.location.search.match(/[?&]locale=([^&]+)/);
    if (!match) return "";
    try { return decodeURIComponent(match[1]); } catch (_error) { return match[1]; }
  }

  function preferredLocale() {
    var saved = "";
    try { saved = window.localStorage.getItem("noche_error_locale") || ""; } catch (_error) {}
    return normalize(queryLocale() || saved || window.navigator.language || "es");
  }

  function translate(locale) {
    var copy = document.querySelectorAll("[data-copy]");
    var buttons = document.querySelectorAll("[data-locale]");
    var current = document.querySelector(".language-current");
    var picker = document.querySelector(".language-picker");
    var body = document.body;
    var i;

    document.documentElement.setAttribute("lang", locale);
    if (body.getAttribute("data-title-" + locale)) {
      document.title = body.getAttribute("data-title-" + locale);
    }

    for (i = 0; i < copy.length; i += 1) {
      var value = copy[i].getAttribute("data-" + locale);
      if (value) copy[i].textContent = value;
    }

    for (i = 0; i < buttons.length; i += 1) {
      buttons[i].setAttribute("aria-pressed", buttons[i].getAttribute("data-locale") === locale ? "true" : "false");
    }

    if (current) current.textContent = localeNames[locale];
    if (picker && picker.getAttribute("data-label-" + locale)) {
      picker.querySelector("summary").setAttribute("aria-label", picker.getAttribute("data-label-" + locale));
    }
  }

  function chooseLocale(event) {
    var locale = event.currentTarget.getAttribute("data-locale");
    var details = event.currentTarget.parentNode;
    try { window.localStorage.setItem("noche_error_locale", locale); } catch (_error) {}
    translate(locale);
    while (details && details.tagName !== "DETAILS") details = details.parentNode;
    if (details) details.removeAttribute("open");
  }

  var buttons = document.querySelectorAll("[data-locale]");
  var retry = document.querySelector("[data-retry]");
  var i;

  for (i = 0; i < buttons.length; i += 1) {
    buttons[i].addEventListener("click", chooseLocale);
  }

  if (retry) {
    retry.addEventListener("click", function (event) {
      event.preventDefault();
      window.location.reload();
    });
  }

  translate(preferredLocale());
}());
