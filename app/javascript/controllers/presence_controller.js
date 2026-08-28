import { Controller } from "@hotwired/stimulus"
import { cable } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = { scope: String, token: String }

  connect() {
    this.active = true
    this.heartbeat = this.heartbeat.bind(this)
    this.onVis = this.onVis.bind(this)
    document.addEventListener("visibilitychange", this.onVis)
    this.subscribe()
  }

  disconnect() {
    this.active = false
    this.stopHeartbeat()
    document.removeEventListener("visibilitychange", this.onVis)
    this.subscription?.unsubscribe()
    this.subscription = null
  }

  onVis() {
    if (!document.hidden) this.heartbeat()
  }

  async subscribe() {
    const subscription = await cable.subscribeTo(
      { channel: "PresenceChannel", scope: this.scopeValue, token: this.tokenValue },
      {
        connected: () => this.startHeartbeat(),
        disconnected: () => this.stopHeartbeat(),
        rejected: () => this.stopHeartbeat()
      }
    )
    if (!this.active) {
      subscription.unsubscribe()
      return
    }
    this.subscription = subscription
  }

  startHeartbeat() {
    if (!this.active) return
    this.stopHeartbeat()
    this.heartbeat()
    this.timer = window.setInterval(this.heartbeat, 20000)
  }

  stopHeartbeat() {
    window.clearInterval(this.timer)
    this.timer = null
  }

  heartbeat() {
    if (!this.active || document.hidden) return
    this.subscription?.perform("heartbeat")
  }
}
