// Module-local state shared by the synchronous gesture unlock and the backend
// loaded immediately afterwards. Keeping it in the module graph avoids an
// application global while preserving the same AudioContext across Turbo visits.
export const audioSession = {
  context: null,
  unlocked: false
}
