export function syncMuteControl(element, muted) {
  element.setAttribute("aria-pressed", muted ? "true" : "false")
  element.classList.toggle("is-muted", muted)

  const word = element.querySelector(".word")
  const on = element.dataset.soundOn || "Activado"
  const off = element.dataset.soundOff || "Desactivado"
  if (word) word.textContent = muted ? off : on
  element.setAttribute("aria-label", muted ? off : on)
}
