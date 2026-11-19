-- UI Visibility: action bars module
-- Action Bars 1 to 8, using the element engine. Names match Edit Mode:
-- Action Bar 1 is MainActionBar, 2 is MultiBarBottomLeft, and so on.
--
-- These are protected bars: addons can't change their buttons' mouse in
-- combat. Opacity can change at any time; a mouse change made in combat is
-- applied when combat ends.

local ADDON_NAME, ns = ...

ns.AddLocale("en", {
    tab_actionbars = "Action bars",
    ab_title = "Action Bars",
    ab_bar = "Action Bar %d",
    ab_note = "Keybinds always work. Changes made in combat apply when it ends.",
})
ns.AddLocale("es", {
    tab_actionbars = "Barras acción",
    ab_title = "Barras de acción",
    ab_bar = "Barra de acción %d",
    ab_note = "Los atajos siempre funcionan. Los cambios en combate se aplican al terminar.",
})

local BAR_FRAMES = {
    "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight",
    "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7",
}

-- Each label is built from "Action Bar %d" in the current language.
for i = 1, #BAR_FRAMES do
    ns.AddLocale("en", { ["ab_bar" .. i] = string.format(ns.LOCALES.en.ab_bar, i) })
    ns.AddLocale("es", { ["ab_bar" .. i] = string.format(ns.LOCALES.es.ab_bar, i) })
end

local elements, modes = {}, {}
for i, frameName in ipairs(BAR_FRAMES) do
    elements[i] = { key = "bar" .. i, label = "ab_bar" .. i, frame = frameName }
    modes["bar" .. i] = "shown"
end

local L = ns.Lproxy
local mod

ns.AddLocale("en", {
    ab_keepButtons = "Glowing buttons hide with their bar",
    ab_keepButtons_tip = "Some addons, like Glowing Bars, make glowing buttons ignore their bar's opacity so they always show. "
        .. "On: buttons on bars that UI Visibility hides or fades follow their bar, glow included. Bars set to Shown aren't affected.",
})
ns.AddLocale("es", {
    ab_keepButtons = "Los botones brillantes se ocultan con su barra",
    ab_keepButtons_tip = "Algunos addons, como Glowing Bars, hacen que los botones que brillan ignoren la opacidad de su barra para verse siempre. "
        .. "Activado: los botones de barras que UI Visibility oculta o desvanece siguen a su barra, brillo incluido. Las barras en Visible no se ven afectadas.",
})

mod = ns.NewElementsModule({
    key = "actionbars", titleKey = "ab_title", tabKey = "tab_actionbars",
    noteKey = "ab_note",
    elements = elements,
    defaults = { enabled = true, linkHover = false, modes = modes, keepButtons = true },
    extraOptions = function(parent, y, add, changed)
        add(ns.CreateCheck(parent, L.ab_keepButtons, y,
            function() return mod.db.keepButtons end,
            function(v) mod.db.keepButtons = v; changed() end,
            { tooltip = L.ab_keepButtons_tip, width = 360 }))
        return y - 28
    end,
})

---------------------------------------------------------------------------
-- Buttons that ignore their bar's opacity
---------------------------------------------------------------------------
-- Glowing Bars (and similar addons) call SetIgnoreParentAlpha(true) on
-- glowing buttons so they show at full opacity whatever their bar's. On a
-- bar UI Visibility hides or fades, that makes the button and its glow pop
-- out. Each button of a controlled bar is hooked: when it's told to ignore
-- its bar, it's set back right away (Glowing Bars only sets it once per
-- glow, so they don't fight). A check every second covers buttons that
-- already ignored their bar before it became controlled, and buttons whose
-- state the game doesn't report. /uiv actionbars glow shows what's going on.
local buttonBar = {} -- button -> element key of its bar
local hooked = {}
local BUTTON_PREFIXES = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton",
    "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button",
}

local function Controlled(key)
    local db = mod.db
    return db and db.enabled and db.keepButtons and db.modes[key] ~= "shown" and not ns.IsEditMode() or false
end

-- true, false, or nil when the game doesn't say.
local function Ignoring(button)
    if not button.IsIgnoringParentAlpha then return nil end
    local ok, v = pcall(button.IsIgnoringParentAlpha, button)
    if not ok or ns.IsSecret(v) then return nil end
    return v == true
end

local function Follow(button)
    local key = buttonBar[button]
    if key and Controlled(key) and Ignoring(button) ~= false then
        pcall(button.SetIgnoreParentAlpha, button, false)
    end
end

-- The buttons of a bar: its children, plus the standard button names (in
-- case they sit inside another frame of the bar).
local function BarButtons(bar, index)
    local list, seen = {}, {}
    local function addButton(b)
        if b and not seen[b] and b.SetIgnoreParentAlpha then
            seen[b] = true
            list[#list + 1] = b
        end
    end
    for _, child in ipairs({ bar:GetChildren() }) do addButton(child) end
    for i = 1, 12 do addButton(_G[BUTTON_PREFIXES[index] .. i]) end
    return list
end

local function TrackBar(bar, index, key)
    for _, button in ipairs(BarButtons(bar, index)) do
        buttonBar[button] = key
        if not hooked[button] then
            hooked[button] = true
            hooksecurefunc(button, "SetIgnoreParentAlpha", function(self, ignore)
                if ignore then Follow(self) end
            end)
        end
        Follow(button)
    end
end

-- /uiv actionbars glow: what each bar and its buttons are doing.
local function PrintGlow()
    for i, element in ipairs(elements) do
        local bar = ns.Resolve(element.frame)
        if not bar then
            ns.Print(L[element.label] .. ": " .. L.notFound)
        else
            local buttons = BarButtons(bar, i)
            local standing = {}
            for _, b in ipairs(buttons) do
                if Ignoring(b) ~= false then
                    local ok, eff = pcall(b.GetEffectiveAlpha, b)
                    standing[#standing + 1] = string.format("%s (%s, %s)", b:GetName() or "?",
                        Ignoring(b) == nil and "?" or "ignoring",
                        ok and not ns.IsSecret(eff) and string.format("%.2f", eff) or "?")
                end
            end
            local okA, alpha = pcall(bar.GetAlpha, bar)
            ns.Print(string.format("%s: mode %s, controlled %s, bar alpha %s, %d buttons, %d hooked, ignoring: %s",
                L[element.label], tostring(mod.db.modes[element.key]), tostring(Controlled(element.key)),
                okA and not ns.IsSecret(alpha) and string.format("%.2f", alpha) or "?",
                #buttons, (function() local n = 0 for _, b in ipairs(buttons) do if hooked[b] then n = n + 1 end end return n end)(),
                #standing > 0 and table.concat(standing, ", ") or "none"))
        end
    end
end

function mod.Command(cmd)
    if cmd == "glow" then PrintGlow(); return true end
end

local nextCheck = 0
local engineTick = mod.OnTick
function mod.OnTick(now)
    engineTick(now)
    if now < nextCheck then return end
    nextCheck = now + 1
    for i, element in ipairs(elements) do
        local bar = ns.Resolve(element.frame)
        if bar and bar.GetChildren then TrackBar(bar, i, element.key) end
    end
end
