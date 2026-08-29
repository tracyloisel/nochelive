import { Controller } from "@hotwired/stimulus"
import { audioLoader } from "platform/audio/loader"
import { syncMuteControl } from "platform/audio/mute_control"

// Contextual DOM adapter. The native backend is isolated behind the same port
// that a validated Howler backend will implement during the audio cutover.
export default class extends Controller {
  static targets = ["mute"]

  connect() {
    audioLoader.connect()
    this.syncMute()
  }

  disconnect() {
    audioLoader.disconnect()
  }

  toggleMute(event) {
    event?.preventDefault()
    event?.stopPropagation()
    audioLoader.toggleMute().catch(() => {}).finally(() => this.syncMute())
  }

  play(name, gainValue) {
    audioLoader.play(name, gainValue)
  }

  flash(name) {
    audioLoader.flash(name)
  }

  syncMute() {
    if (!this.hasMuteTarget) return
    syncMuteControl(this.muteTarget, audioLoader.muted())
  }
}
