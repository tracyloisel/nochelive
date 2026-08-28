import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "status", "feedback", "frequency", "time", "enableChallenges", "disableChallenges",
    "enableVerses", "disableVerses", "reassign", "install", "disableDevice", "controls"
  ]

  static values = {
    subscriptionUrl: String, preferencesUrl: String, promptUrl: String, publicKey: String,
    personName: String, category: String, context: String, automatic: Boolean,
    challengesActive: Boolean, versesActive: Boolean, loadingText: String, allowedText: String,
    defaultText: String, deniedText: String, unsupportedText: String, installText: String,
    savedText: String, disabledDeviceText: String, failedText: String, reassignText: String,
    deviceExpiredText: String, deviceSubscribed: Boolean
  }

  connect() {
    this.messageHandler = (event) => {
      if (event.data?.type === "noche:push-subscription-change") {
        this.deviceSubscribedValue = false
        this.setStatus(this.deviceExpiredTextValue)
        this.syncButtons()
      }
    }
    navigator.serviceWorker?.addEventListener("message", this.messageHandler)
    this.observeSettingsFocus()
    this.refresh()
  }

  disconnect() {
    navigator.serviceWorker?.removeEventListener("message", this.messageHandler)
    this.settingsObserver?.disconnect()
    document.body.classList.remove("is-reading-push-settings")
  }

  async refresh() {
    this.setStatus(this.loadingTextValue)
    if (this.automaticValue && this.sessionBlocked()) return this.hide()
    if (!this.supported()) {
      this.channelUnavailable = true
      this.syncButtons()
      return this.automaticValue ? this.hide() : this.showState(this.unsupportedTextValue)
    }
    if (this.isIos() && !this.isStandalone()) return this.showInstallState()

    if (Notification.permission === "denied") {
      this.channelUnavailable = true
      this.syncButtons()
      await this.record("system_denied")
      return this.automaticValue ? this.hide() : this.showState(this.deniedTextValue)
    }

    if (Notification.permission === "granted") {
      const registration = await navigator.serviceWorker.ready
      const browserSubscription = await registration.pushManager.getSubscription()
      if (!browserSubscription || !this.deviceSubscribedValue) {
        this.deviceSubscribedValue = false
        this.showState(this.deviceExpiredTextValue)
      } else {
        this.showState(this.allowedTextValue)
      }
    } else {
      this.deviceSubscribedValue = false
      this.showState(this.defaultTextValue)
    }
    if (this.automaticValue) {
      this.markSessionPrompt()
      await this.record("offered")
    }
    this.syncButtons()
  }

  async enable(event) {
    const category = event.currentTarget.dataset.category || this.categoryValue
    if (!this.supported()) return this.showFailure(this.unsupportedTextValue)
    if (this.isIos() && !this.isStandalone()) return this.rememberInstall()

    this.setBusy(true)
    try {
      let permission = Notification.permission
      if (permission === "default") permission = await Notification.requestPermission()
      if (permission !== "granted") {
        this.channelUnavailable = true
        this.syncButtons()
        await this.record("system_denied", category)
        this.setStatus(this.deniedTextValue)
        this.showFailure(this.deniedTextValue)
        return
      }

      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription() || await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.applicationServerKey()
      })
      await this.finishSubscription(subscription, category, false)
    } catch (_) {
      this.showFailure(this.failedTextValue)
    } finally {
      this.setBusy(false)
    }
  }

  async confirmReassignment(event) {
    const category = event.currentTarget.dataset.category || this.categoryValue
    this.setBusy(true)
    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()
      if (!subscription) throw new Error("subscription missing")
      await this.finishSubscription(subscription, category, true)
    } catch (_) {
      this.showFailure(this.failedTextValue)
    } finally {
      this.setBusy(false)
    }
  }

  async finishSubscription(subscription, category, reassign) {
    const response = await this.request(this.subscriptionUrlValue, {
      method: "POST",
      body: JSON.stringify({
        subscription: subscription.toJSON(), category, context: this.contextValue || "profile",
        time_zone: Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC",
        verse_frequency: this.hasFrequencyTarget ? this.frequencyTarget.value : "three_weekly",
        verse_local_time: this.hasTimeTarget ? this.timeTarget.value : "08:00", reassign
      })
    })

    if (response.status === 409) {
      this.element.querySelectorAll(".push-primary, .push-setting-action").forEach((button) => { button.hidden = true })
      this.reassignTargets.forEach((button) => {
        button.hidden = false
        button.dataset.category = category
      })
      this.showFailure(this.reassignTextValue)
      return
    }
    if (!response.ok) throw new Error("subscription rejected")

    if (category === "challenges") this.challengesActiveValue = true
    if (category === "verses") this.versesActiveValue = true
    this.deviceSubscribedValue = true
    this.channelUnavailable = false
    this.setStatus(this.allowedTextValue)
    this.showFeedback(this.savedTextValue)
    this.syncButtons()
    await this.record("activated", category)
  }

  async disableCategory(event) {
    const category = event.currentTarget.dataset.category
    this.setBusy(true)
    try {
      const response = await this.request(this.preferencesUrlValue, {
        method: "PATCH", body: JSON.stringify({ category, enabled: false })
      })
      if (!response.ok) throw new Error("preference rejected")
      if (category === "challenges") this.challengesActiveValue = false
      if (category === "verses") this.versesActiveValue = false
      this.showFeedback(this.savedTextValue)
      this.syncButtons()
    } catch (_) {
      this.showFailure(this.failedTextValue)
    } finally {
      this.setBusy(false)
    }
  }

  async disableDevice() {
    this.setBusy(true)
    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()
      const response = await this.request(this.subscriptionUrlValue, {
        method: "DELETE", body: JSON.stringify({ endpoint: subscription?.endpoint })
      })
      if (!response.ok) throw new Error("unsubscribe rejected")
      if (subscription) await subscription.unsubscribe()
      this.deviceSubscribedValue = false
      this.syncButtons()
      this.showFeedback(this.disabledDeviceTextValue)
      this.setStatus(this.defaultTextValue)
    } catch (_) {
      this.showFailure(this.failedTextValue)
    } finally {
      this.setBusy(false)
    }
  }

  async dismiss() {
    await this.record("dismissed")
    this.hide()
  }

  rememberInstall() {
    try {
      sessionStorage.setItem("noche:pwa-install-offered", "1")
      sessionStorage.setItem("noche:push-interest", this.categoryValue)
    } catch (_) {}
    this.markSessionPrompt()
    this.record("selected")
  }

  showInstallState() {
    this.element.classList.add("is-install-required")
    this.installRequired = true
    this.channelUnavailable = true
    this.syncButtons()
    this.showState(this.installTextValue)
    if (this.automaticValue) {
      this.markSessionPrompt()
      this.record("offered")
    }
  }

  syncButtons() {
    const canEnable = !this.channelUnavailable
    this.enableChallengesTargets.forEach((button) => { button.hidden = !canEnable || (this.challengesActiveValue && this.deviceSubscribedValue) })
    this.disableChallengesTargets.forEach((button) => { button.hidden = !this.challengesActiveValue })
    this.enableVersesTargets.forEach((button) => { button.hidden = !canEnable || (this.versesActiveValue && this.deviceSubscribedValue) })
    this.disableVersesTargets.forEach((button) => { button.hidden = !this.versesActiveValue })
    this.installTargets.forEach((button) => { button.hidden = !this.installRequired })
    this.disableDeviceTargets.forEach((button) => { button.hidden = !this.deviceSubscribedValue })
  }

  async updateVerseChoice() {
    this.updateVerseCta()
    if (!this.versesActiveValue) return

    this.setBusy(true)
    try {
      const response = await this.request(this.preferencesUrlValue, {
        method: "PATCH",
        body: JSON.stringify({
          category: "verses", enabled: true,
          verse_frequency: this.frequencyTarget.value,
          verse_local_time: this.timeTarget.value
        })
      })
      if (!response.ok) throw new Error("preference rejected")
      this.showFeedback(this.savedTextValue)
    } catch (_) {
      this.showFailure(this.failedTextValue)
    } finally {
      this.setBusy(false)
    }
  }

  updateVerseCta() {
    if (!this.hasFrequencyTarget || !this.hasTimeTarget) return
    const label = this.frequencyTarget.selectedOptions[0]?.dataset.label || this.frequencyTarget.selectedOptions[0]?.textContent || ""
    this.enableVersesTargets.forEach((button) => {
      const template = button.dataset.template
      if (template) button.textContent = template.replace("__FREQUENCY__", label).replace("__TIME__", this.timeTarget.value)
    })
  }

  async record(result, category = this.categoryValue) {
    if (!category || !this.promptUrlValue) return
    try {
      await this.request(this.promptUrlValue, {
        method: "PATCH", body: JSON.stringify({ category, result, context: this.contextValue || "profile" })
      })
    } catch (_) {}
  }

  request(url, options) {
    return fetch(url, {
      credentials: "same-origin",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": this.csrfToken() },
      ...options
    })
  }

  csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }

  applicationServerKey() {
    const padding = "=".repeat((4 - this.publicKeyValue.length % 4) % 4)
    const base64 = (this.publicKeyValue + padding).replace(/-/g, "+").replace(/_/g, "/")
    return Uint8Array.from(atob(base64), (character) => character.charCodeAt(0))
  }

  supported() {
    return "serviceWorker" in navigator && "PushManager" in window && "Notification" in window && this.publicKeyValue.length > 0
  }

  sessionBlocked() {
    try {
      return sessionStorage.getItem("noche:push-prompt-shown") === "1" || sessionStorage.getItem("noche:pwa-install-offered") === "1"
    } catch (_) { return false }
  }

  markSessionPrompt() {
    try { sessionStorage.setItem("noche:push-prompt-shown", "1") } catch (_) {}
  }

  setBusy(busy) {
    this.element.classList.toggle("is-loading", busy)
    this.controlsTargets.forEach((control) => { control.disabled = busy })
  }

  setStatus(message) { this.statusTargets.forEach((target) => { target.textContent = message }) }

  showFeedback(message) {
    this.feedbackTargets.forEach((target) => {
      target.hidden = false
      target.classList.remove("is-error")
      target.textContent = message
    })
  }

  showFailure(message) {
    this.feedbackTargets.forEach((target) => {
      target.hidden = false
      target.classList.add("is-error")
      target.textContent = message
    })
  }

  showState(message) {
    this.element.hidden = false
    this.setStatus(message)
  }

  hide() { this.element.hidden = true }

  isIos() {
    return /iphone|ipad|ipod/i.test(navigator.userAgent) ||
      (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
  }

  isStandalone() {
    return window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true
  }

  observeSettingsFocus() {
    if (this.automaticValue || !("IntersectionObserver" in window)) return

    this.settingsObserver = new IntersectionObserver((entries) => {
      document.body.classList.toggle("is-reading-push-settings", entries.some((entry) => entry.isIntersecting))
    }, { threshold: 0.08 })
    this.settingsObserver.observe(this.element)
  }
}
