# Pin npm packages by running ./bin/importmap

pin "application"
pin "haptics", to: "haptics.js", preload: false
pin "howler-core", to: "howler-core-2.2.4.js", preload: false
pin "motion", to: "motion-13.1.1.js", preload: false
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers", preload: false
pin_all_from "app/javascript/platform", under: "platform", preload: false
pin_all_from "app/javascript/runtime", under: "runtime", preload: false
pin_all_from "app/javascript/features", under: "features", preload: false
