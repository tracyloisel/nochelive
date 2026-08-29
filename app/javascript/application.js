// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

window.Turbo.StreamActions.quiz_state = function() {
  const marker = this.templateContent.firstElementChild
  if (!marker) return

  this.targetElements.forEach((target) => {
    target.className = marker.className

    Array.from(target.attributes).forEach((attribute) => {
      if (!attribute.name.startsWith("data-")) return
      if ([ "data-controller", "data-action" ].includes(attribute.name)) return
      target.removeAttribute(attribute.name)
    })

    Array.from(marker.attributes).forEach((attribute) => {
      if (!attribute.name.startsWith("data-")) return
      if ([ "data-controller", "data-action" ].includes(attribute.name)) return
      target.setAttribute(attribute.name, attribute.value)
    })

    target.dispatchEvent(new CustomEvent("quiz:state", { bubbles: true }))
  })
}

window.Turbo.StreamActions.quiz_deferred_replace = function() {
  const targets = this.targetElements
  const content = this.templateContent

  window.setTimeout(() => {
    targets.forEach((target) => {
      if (!target.isConnected) return
      target.replaceWith(content.cloneNode(true))
    })
  }, 0)
}

function mountFontStylesheet() {
  const preload = document.head.querySelector("link[data-noche-font-preload]")
  if (!preload) return

  const href = preload.href
  const mounted = [...document.head.querySelectorAll('link[rel="stylesheet"]')]
    .some((link) => link.href === href)
  if (mounted) return

  const stylesheet = document.createElement("link")
  stylesheet.rel = "stylesheet"
  stylesheet.href = href
  stylesheet.dataset.nocheFontStylesheet = "true"
  document.head.append(stylesheet)
}

mountFontStylesheet()
document.addEventListener("turbo:load", mountFontStylesheet)
