-- Toggle a persistent OSD showing the current frame number.
-- Bind a key to `script-message frame-overlay-toggle` (see input.conf).

local mp = mp
local active = false
local overlay = mp.create_osd_overlay("ass-events")

local function update()
    if not active then return end
    local n = mp.get_property_number("estimated-frame-number")
    overlay.data = string.format("{\\an9\\fs28\\bord2}Frame: %s", n or "?")
    overlay:update()
end

local function clear()
    overlay.data = ""
    overlay:update()
end

mp.register_event("tick", update)
mp.observe_property("estimated-frame-number", "number", update)

mp.register_script_message("frame-overlay-toggle", function()
    active = not active
    if active then update() else clear() end
end)
