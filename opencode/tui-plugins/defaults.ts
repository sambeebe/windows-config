// defaults: TUI preferences that opencode keeps in its kv store rather than
// in tui.json, re-applied on every start so a new machine comes up the same.
//
//   sidebar                hidden ("auto" shows it on windows wider than 120
//                          columns); <leader>b still toggles it per session
//   paste_summary_enabled  off, so pasted text isn't collapsed to
//                          "[Pasted ~N lines]". This kv value overrides
//                          experimental.disable_paste_summary in opencode.json
//                          once it has ever been toggled, so set both.
//
// Key names come from the opencode TUI source (1.19).

import type { TuiPlugin } from "@opencode-ai/plugin/tui"

const DEFAULTS: Record<string, unknown> = {
  sidebar: "hide",
  paste_summary_enabled: false,
}

const tui: TuiPlugin = async (api) => {
  const apply = () => {
    for (const [key, value] of Object.entries(DEFAULTS)) api.kv.set(key, value)
  }
  if (api.kv.ready) return apply()
  const wait = setInterval(() => {
    if (!api.kv.ready) return
    clearInterval(wait)
    apply()
  }, 25)
}

export default { id: "defaults", tui }
