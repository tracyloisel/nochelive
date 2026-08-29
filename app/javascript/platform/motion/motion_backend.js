import { animate, stagger } from "motion"

export const motionBackend = Object.freeze({
  animate(elements, keyframes, options) {
    return animate(elements, keyframes, options)
  },

  stagger(interval, options = {}) {
    return stagger(interval, options)
  }
})
