// copy-code: copy fenced code blocks from assistant replies.
//
//   <leader>k   pick any block in the session, newest reply first (Enter copies it)
//   alt+1..9    copy block N of the latest reply directly
//
// Keys can be overridden via plugin options in tui.json:
//   "plugin": [["./tui-plugins/copy-code.ts", { "pick": "<leader>k", "direct": "alt" }]]
// Set "direct": false to disable the numbered shortcuts.
//
// Lives outside ~/.config/opencode/plugins/ on purpose: that directory is
// auto-loaded as *server* plugins, and this is a TUI-only plugin.

import type { TuiPlugin, TuiPluginApi } from "@opencode-ai/plugin/tui"
import { spawn, spawnSync } from "node:child_process"

type Block = { lang: string; code: string }

function extractBlocks(text: string): Block[] {
  const blocks: Block[] = []
  let open: { indent: string; fence: string; lang: string; lines: string[] } | undefined
  for (const line of text.split("\n")) {
    if (!open) {
      const m = line.match(/^([ \t]*)(`{3,}|~{3,})[ \t]*([^\s`]*)/)
      if (m) open = { indent: m[1], fence: m[2], lang: m[3], lines: [] }
      continue
    }
    const close = line.match(/^[ \t]*(`{3,}|~{3,})[ \t]*$/)
    if (close && close[1][0] === open.fence[0] && close[1].length >= open.fence.length) {
      // Strip the fence's own indentation (e.g. fences nested in list items).
      const code = open.lines
        .map((l) => (open!.indent && l.startsWith(open!.indent) ? l.slice(open!.indent.length) : l))
        .join("\n")
        .replace(/\s+$/, "")
      if (code) blocks.push({ lang: open.lang, code })
      open = undefined
      continue
    }
    open.lines.push(line)
  }
  return blocks
}

type Reply = { prompt: string; blocks: Block[] }

function textOf(api: TuiPluginApi, messageIDs: string[]) {
  return messageIDs
    .flatMap((id) => api.state.part(id))
    .filter((p) => p.type === "text" && !(p as { synthetic?: boolean }).synthetic)
    .map((p) => (p as { text: string }).text)
    .join("\n")
}

// Every reply in the session that contains code blocks, newest first. A reply is
// all assistant messages after a user message, so a turn split across tool
// calls counts as one.
function currentSession(api: TuiPluginApi) {
  const route = api.route.current
  return route.name === "session" ? (route.params?.sessionID as string | undefined) : undefined
}

function replies(api: TuiPluginApi): Reply[] | string {
  const sessionID = currentSession(api)
  if (!sessionID) return "Open a session first"

  const result: Reply[] = []
  let prompt = ""
  let assistant: string[] = []
  const flush = () => {
    const blocks = extractBlocks(textOf(api, assistant))
    if (blocks.length) result.push({ prompt, blocks })
    assistant = []
  }
  for (const m of api.state.session.messages(sessionID)) {
    if (m.role === "user") {
      flush()
      prompt = textOf(api, [m.id]).replace(/\s+/g, " ").trim()
    } else assistant.push(m.id)
  }
  flush()
  return result.length ? result.reverse() : "No code blocks in this session"
}

// Blocks from the latest reply only (what alt+N indexes into).
function latestBlocks(api: TuiPluginApi): Block[] | string {
  const sessionID = currentSession(api)
  if (!sessionID) return "Open a session first"
  const messages = api.state.session.messages(sessionID)
  const lastUser = messages.findLastIndex((m) => m.role === "user")
  const turn = messages.slice(lastUser + 1).map((m) => m.id)
  const blocks = extractBlocks(textOf(api, turn))
  return blocks.length ? blocks : "No code blocks in the last reply"
}

function has(bin: string) {
  return spawnSync("sh", ["-c", `command -v ${bin}`], { stdio: "ignore" }).status === 0
}

let nativeCopy: string[] | null | undefined
function copyCommand() {
  if (nativeCopy !== undefined) return nativeCopy
  if (process.platform === "darwin") nativeCopy = ["pbcopy"]
  else if (process.platform === "win32")
    nativeCopy = [
      "powershell.exe",
      "-NonInteractive",
      "-NoProfile",
      "-Command",
      "[Console]::InputEncoding = [System.Text.Encoding]::UTF8; Set-Clipboard -Value ([Console]::In.ReadToEnd())",
    ]
  else if (process.env.WAYLAND_DISPLAY && has("wl-copy")) nativeCopy = ["wl-copy"]
  else if (has("xclip")) nativeCopy = ["xclip", "-selection", "clipboard"]
  else if (has("xsel")) nativeCopy = ["xsel", "--clipboard", "--input"]
  else nativeCopy = null
  return nativeCopy
}

// Same strategy as opencode's own clipboard: OSC 52 (works over SSH) plus the
// native tool when one exists. A native failure only counts if OSC 52 wasn't sent.
function writeClipboard(text: string): Promise<void> {
  const osc52 = process.stdout.isTTY
  if (osc52) {
    const seq = `\x1b]52;c;${Buffer.from(text).toString("base64")}\x07`
    const passthrough = `\x1bPtmux;\x1b${seq}\x1b\\`
    process.stdout.write(process.env.TMUX ? seq + passthrough : process.env.STY ? passthrough : seq)
  }
  const cmd = copyCommand()
  if (!cmd) return osc52 ? Promise.resolve() : Promise.reject(new Error("no clipboard tool found"))
  const native = new Promise<void>((resolve, reject) => {
    const child = spawn(cmd[0], cmd.slice(1), { stdio: ["pipe", "ignore", "ignore"] })
    child.on("error", reject)
    child.on("close", (code) => (code === 0 ? resolve() : reject(new Error(`${cmd[0]} exited ${code}`))))
    child.stdin.end(text)
  })
  return osc52 ? native.catch(() => {}) : native
}

function preview(code: string, width = 70) {
  const first = code.split("\n")[0]
  const lines = code.split("\n").length
  const head = first.length > width ? first.slice(0, width - 1) + "…" : first
  return lines > 1 ? `${head}  (+${lines - 1} lines)` : head
}

async function copyBlock(api: TuiPluginApi, block: Block, n: number) {
  try {
    await writeClipboard(block.code)
    api.ui.toast({ variant: "success", message: `Copied block ${n}: ${preview(block.code, 50)}` })
  } catch (err) {
    api.ui.toast({ variant: "error", message: `Copy failed: ${(err as Error).message}` })
  }
}

function pick(api: TuiPluginApi) {
  const all = replies(api)
  if (typeof all === "string") return api.ui.toast({ variant: "warning", message: all })

  const items = all.flatMap((reply, r) =>
    reply.blocks.map((block, i) => ({ block, n: i + 1, r, prompt: reply.prompt })),
  )
  api.ui.dialog.replace(() =>
    api.ui.DialogSelect({
      title: "Copy code block",
      placeholder: "Filter blocks",
      options: items.map((item, idx) => ({
        title: `${item.n}. ${preview(item.block.code)}`,
        value: idx,
        description: item.block.lang || undefined,
        // Grouped under the prompt that produced the reply; r keeps headers unique.
        category: `${item.r === 0 ? "Latest" : `${item.r} back`} · ${preview(item.prompt || "(no prompt)", 50)}`,
      })),
      onSelect: (option) => {
        api.ui.dialog.clear()
        const item = items[option.value as number]
        copyBlock(api, item.block, item.n)
      },
    }),
  )
}

function copyNth(api: TuiPluginApi, n: number) {
  const blocks = latestBlocks(api)
  if (typeof blocks === "string") return api.ui.toast({ variant: "warning", message: blocks })
  const block = blocks[n - 1]
  if (!block) return api.ui.toast({ variant: "warning", message: `Only ${blocks.length} block(s) in the last reply` })
  copyBlock(api, block, n)
}

const tui: TuiPlugin = async (api, options) => {
  const opts = (options ?? {}) as { pick?: string | false; direct?: string | false }
  const pickKey = opts.pick ?? "<leader>k"
  const directMod = opts.direct ?? "alt"

  const nums = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  api.keymap.registerLayer({
    commands: [
      {
        name: "copy_code.pick",
        title: "Copy code block…",
        category: "Session",
        namespace: "palette",
        run: () => {
          pick(api)
        },
      },
      ...nums.map((n) => ({
        name: `copy_code.${n}`,
        title: `Copy code block ${n}`,
        hidden: true,
        run: () => {
          copyNth(api, n)
        },
      })),
    ],
    bindings: [
      ...(pickKey ? [{ key: pickKey, cmd: "copy_code.pick" }] : []),
      ...(directMod ? nums.map((n) => ({ key: `${directMod}+${n}`, cmd: `copy_code.${n}` })) : []),
    ],
  })
}

export default { id: "copy-code", tui }
