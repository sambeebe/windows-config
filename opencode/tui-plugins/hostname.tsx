/** @jsxImportSource @opentui/solid */
// hostname: show the machine name at the right of the prompt bar, so it's
// obvious which computer this opencode is running on.
//
// Off unless SHOW_HOSTNAME is truthy (1/true/yes/on) — the same variable the
// zsh prompt reads. Set it with `set-env SHOW_HOSTNAME 1` (zsh or pwsh) and
// restart opencode; it's read once at startup.

import type { TuiPlugin } from "@opencode-ai/plugin/tui"
import { hostname } from "node:os"

const tui: TuiPlugin = async (api) => {
  if (!/^(1|true|yes|on)$/i.test(process.env.SHOW_HOSTNAME ?? "")) return
  const host = hostname().split(".")[0]
  const label = () => <text fg={api.theme.current.warning}>{host}</text>
  api.slots.register({
    slots: {
      home_prompt_right: label,
      session_prompt_right: label,
    },
  })
}

export default { id: "hostname", tui }
