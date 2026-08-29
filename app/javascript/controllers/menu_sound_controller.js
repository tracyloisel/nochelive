import { Controller } from "@hotwired/stimulus"
import { audioLoader } from "platform/audio/loader"
import { syncMuteControl } from "platform/audio/mute_control"

export default class extends Controller {
  connect() {
    this.sync()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    audioLoader.toggleMute().catch(() => {}).finally(() => this.sync())
  }

  sync() {
    syncMuteControl(this.element, audioLoader.muted())
  }
}
