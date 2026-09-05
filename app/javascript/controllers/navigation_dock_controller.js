import AdaptiveSurfaceController from "platform/chrome/adaptive_surface_controller"

export default class extends AdaptiveSurfaceController {
  readTheme() {
    return this.element.dataset?.dockTheme ?? this.element.getAttribute?.("data-dock-theme")
  }

  writeTheme(theme) {
    if (this.element.dataset) {
      if (this.element.dataset.dockTheme !== theme) this.element.dataset.dockTheme = theme
    } else if (this.element.getAttribute?.("data-dock-theme") !== theme) {
      this.element.setAttribute?.("data-dock-theme", theme)
    }
  }
}
