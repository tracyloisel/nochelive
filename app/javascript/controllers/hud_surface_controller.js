import AdaptiveSurfaceController from "platform/chrome/adaptive_surface_controller"

export default class extends AdaptiveSurfaceController {
  readTheme() {
    return this.themeFrom(this.element) || this.themeFrom(this.menuElement())
  }

  writeTheme(theme) {
    this.writeThemeTo(this.element, theme)
    this.writeThemeTo(this.menuElement(), theme)
    this.themeCompanions().forEach((element) => this.writeThemeTo(element, theme))
  }

  menuElement() {
    return this.element.closest?.(".home-menu")
  }

  themeCompanions() {
    try {
      return Array.from(document.querySelectorAll?.("[data-hud-theme-companion]") || [])
    } catch (_error) {
      return []
    }
  }

  themeFrom(element) {
    return element?.dataset?.hudTheme ?? element?.getAttribute?.("data-hud-theme")
  }

  writeThemeTo(element, theme) {
    if (!element) return

    if (element.dataset) {
      if (element.dataset.hudTheme !== theme) element.dataset.hudTheme = theme
    } else if (element.getAttribute?.("data-hud-theme") !== theme) {
      element.setAttribute?.("data-hud-theme", theme)
    }
  }
}
