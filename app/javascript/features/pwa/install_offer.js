import { SafeStorage } from "platform/storage/safe_storage"

const INSTALL_SNOOZE_MS = 14 * 24 * 60 * 60 * 1000
const BANNER_SNOOZE_AT_KEY = "noche:pwa-install-banner-snoozed-at"
const DISMISSED_AT_KEY = "noche:pwa-install-dismissed-at"
const IOS_GUIDE_SEEN_AT_KEY = "noche:pwa-install-ios-guide-seen-at"
const INSTALLED_AT_KEY = "noche:pwa-install-installed-at"
const OFFERED_SESSION_KEY = "noche:pwa-install-offered"
const REJECTED_AT_KEY = "noche:pwa-install-rejected-at"

export class InstallOfferMemory {
  constructor({ localStorage, now = () => Date.now(), sessionStorage } = {}) {
    this.local = new SafeStorage(localStorage || window.localStorage)
    this.now = now
    this.session = new SafeStorage(sessionStorage || window.sessionStorage)
  }

  markInstalled() { this.writeTimestamp(INSTALLED_AT_KEY) }
  markIosGuideSeen() { this.writeTimestamp(IOS_GUIDE_SEEN_AT_KEY) }
  markOfferSeen() { this.session.set(OFFERED_SESSION_KEY, "1") }
  recordRejection() { this.writeTimestamp(REJECTED_AT_KEY) }
  snoozeBanner() { this.writeTimestamp(BANNER_SNOOZE_AT_KEY) }
  snoozeInstallUi() { this.writeTimestamp(DISMISSED_AT_KEY) }

  knownInstalled() { return this.timestampFor(INSTALLED_AT_KEY) > 0 }
  bannerSnoozed() { return this.recent(BANNER_SNOOZE_AT_KEY) }
  installSnoozed() { return [ DISMISSED_AT_KEY, REJECTED_AT_KEY ].some((key) => this.recent(key)) }

  iosGuideSnoozed() {
    return this.recent(IOS_GUIDE_SEEN_AT_KEY) || this.session.get(OFFERED_SESSION_KEY) === "1"
  }

  recent(key) {
    const timestamp = this.timestampFor(key)
    return timestamp > 0 && this.now() - timestamp < INSTALL_SNOOZE_MS
  }

  timestampFor(key) { return Number(this.local.get(key, 0)) }
  writeTimestamp(key) { this.local.set(key, this.now()) }
}

export function validInstallPrompt(event) {
  return typeof event?.prompt === "function" && typeof event?.userChoice?.then === "function" ? event : null
}

export function isIosDevice(navigator) {
  return /iphone|ipad|ipod/i.test(navigator.userAgent) ||
    (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
}

export function isSafariBrowser(navigator) {
  return /safari/i.test(navigator.userAgent) && !/crios|fxios|edgios|opios/i.test(navigator.userAgent)
}

export function isStandaloneMode(window, navigator) {
  return window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true
}

export function setInstallState(controller, state) {
  const busy = state === "installing"
  const disableAction = busy || state === "awaiting_confirmation"
  const status = disableAction ? controller.installingStatusLabel() : ""

  controller.tileTargets.forEach((tile) => {
    tile.dataset.pwaInstallState = state
    tile.setAttribute("aria-busy", busy.toString())
  })
  controller.actionTargets.forEach((action) => {
    action.dataset.pwaInstallState = state
    action.setAttribute("aria-busy", busy.toString())
    if (action instanceof HTMLButtonElement) action.disabled = disableAction
  })
  controller.statusTargets.forEach((statusTarget) => {
    statusTarget.textContent = status
    statusTarget.hidden = status.length === 0
  })
}

export function revealInstallOffer(controller) {
  if (!controller.canOfferInstall() || controller.shouldHideInstallOffer()) return controller.hideInstallUi()

  const revealToken = (controller.revealToken || 0) + 1
  controller.revealToken = revealToken
  controller.ensureStylesheet().then(() => {
    if (revealToken !== controller.revealToken || !controller.canOfferInstall() || controller.shouldHideInstallOffer()) return

    setInstallState(controller, "ready")
    controller.tileTargets.forEach((tile) => { tile.hidden = false })
    controller.actionTargets.forEach((action) => { action.hidden = false })
  })
}

export function hideInstallOffer(controller) {
  controller.revealToken = (controller.revealToken || 0) + 1
  controller.actionTargets.forEach((action) => { action.hidden = true })
  controller.tileTargets.forEach((tile) => { tile.hidden = true })
  controller.bannerTargets.forEach((banner) => { banner.hidden = true })
}

export function revealIosInstallBanner(controller) {
  if (window.location.pathname !== "/" || controller.hasTileTarget || controller.installMemory.bannerSnoozed() || controller.shouldHideInstallOffer() || !controller.canOpenIosGuide()) return

  controller.ensureStylesheet().then(() => {
    controller.bannerTargets.forEach((banner) => { banner.hidden = false })
  })
}
