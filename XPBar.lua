-- UI Visibility: experience bar module
--   Hidden by default.
--   Shown while the mouse is over it.
--   Shown for a few seconds after gaining experience or leveling up.
--   Always shown in Edit Mode.
--
-- Performance: the fast tick only works while the mouse check is on, while
-- the bar is shown after an experience gain, or while it's fading.

local ADDON_NAME, ns = ...
local L = ns.Lproxy

local FRAME_NAME = "MainStatusTrackingBarContainer"
local BLIZZ_ADDON = "Blizzard_StatusTrackingBar"

ns.AddLocale("en", {
    tab_xp = "XP bar",
    xp_title = "Experience Bar",
    xp_secShow = "Show the bar",
    xp_secHidden = "When hidden",
    xp_hover = "On mouse hover",
    xp_hover_tip = "Shows the bar while the mouse is over where it is.",
    xp_onGain = "After gaining XP",
    xp_onGain_tip = "Shows the bar for a while after gaining experience or leveling up.",
    xp_duration = "Time shown",
    xp_duration_tip = "How long the bar stays after gaining experience.",
    xp_hiddenOpacity = "Opacity",
    xp_hiddenOpacity_tip = "0% hides it completely. A little opacity helps you remember where it is.",
    xp_r_edit = "Edit Mode", xp_r_disabled = "module disabled", xp_r_hover = "mouse over the bar",
    xp_r_gain = "experience gained (%.1fs left)", xp_r_hidden = "hidden",
})
ns.AddLocale("es", {
    tab_xp = "Barra XP",
    xp_title = "Barra de experiencia",
    xp_secShow = "Mostrar la barra",
    xp_secHidden = "Cuando está oculta",
    xp_hover = "Al pasar el mouse",
    xp_hover_tip = "Muestra la barra mientras el mouse está donde se ubica.",
    xp_onGain = "Al ganar experiencia",
    xp_onGain_tip = "Muestra la barra un momento después de ganar experiencia o subir de nivel.",
    xp_duration = "Tiempo visible",
    xp_duration_tip = "Cuánto tiempo se queda la barra después de ganar experiencia.",
    xp_hiddenOpacity = "Opacidad",
    xp_hiddenOpacity_tip = "0% la oculta por completo. Un poco de opacidad ayuda a recordar dónde está.",
    xp_r_edit = "Modo Edición", xp_r_disabled = "módulo desactivado", xp_r_hover = "mouse sobre la barra",
    xp_r_gain = "experiencia ganada (quedan %.1fs)", xp_r_hidden = "oculta",
})

local mod = {
    key = "xp", titleKey = "xp_title", tabKey = "tab_xp",
    defaults = {
        enabled = true,
        hover = true,
        showOnGain = true,
        gainDuration = 5,
        hiddenAlpha = 0,
    },
}
ns.RegisterModule(mod)

local bar
local showUntil = 0
local dirty = true
local lastReason = "-"

local function TargetAlpha()
    local db = mod.db
    if not db.enabled then lastReason = L.xp_r_disabled; return 1 end
    if ns.IsEditMode() then lastReason = L.xp_r_edit; return 1 end
    if db.hover and ns.IsCursorOver(bar) then lastReason = L.xp_r_hover; return 1 end
    local left = showUntil - GetTime()
    if db.showOnGain and left > 0 then
        lastReason = string.format(L.xp_r_gain, left); return 1
    end
    lastReason = L.xp_r_hidden
    return db.hiddenAlpha / 100
end

function mod.MarkDirty() dirty = true end

function mod.OnTick(now)
    if not bar then return end
    local db = mod.db
    local hoverCheck = db.enabled and db.hover
    if not dirty and not hoverCheck then return end
    local busy = ns.Fade(bar, TargetAlpha())
    -- Keep working while fading or while the "after gain" time runs.
    dirty = busy or now <= showUntil
end

function mod.OnSlowTick()
    dirty = true -- reapply in case the game changed the bar's opacity
end

function mod.SetEnabled(v)
    mod.db.enabled = v
    dirty = true
end

local events = CreateFrame("Frame")
events:SetScript("OnEvent", function()
    showUntil = GetTime() + mod.db.gainDuration
    dirty = true
end)

local function Attach()
    if bar then return end
    bar = _G[FRAME_NAME]
    if not bar then return end
    events:RegisterEvent("PLAYER_XP_UPDATE")
    events:RegisterEvent("PLAYER_LEVEL_UP")
    dirty = true
end

function mod.OnAddonLoaded(name)
    if name == BLIZZ_ADDON then Attach() end
end

function mod.OnLogin()
    Attach()
end

function mod.BuildOptions(parent, y)
    local refreshers = {}
    local function add(r) refreshers[#refreshers + 1] = r end
    local function set(key) return function(v) mod.db[key] = v; dirty = true end end

    add(ns.CreateCheck(parent, L.enabled, y,
        function() return mod.db.enabled end, function(v) mod.SetEnabled(v) end))
    y = y - 40

    ns.CreateSection(parent, L.xp_secShow, y)
    y = y - 32
    add(ns.CreateCheck(parent, L.xp_hover, y, function() return mod.db.hover end, set("hover"),
        { x = 16, width = 160, tooltip = L.xp_hover_tip }))
    add(ns.CreateCheck(parent, L.xp_onGain, y, function() return mod.db.showOnGain end, set("showOnGain"),
        { x = 216, width = 160, tooltip = L.xp_onGain_tip }))
    y = y - 32
    add(ns.CreateStepper(parent, L.xp_duration, y,
        function() return mod.db.gainDuration end, set("gainDuration"), 1, 30, 1, " s",
        { tooltip = L.xp_duration_tip }))
    y = y - 40

    ns.CreateSection(parent, L.xp_secHidden, y)
    y = y - 32
    add(ns.CreateStepper(parent, L.xp_hiddenOpacity, y,
        function() return mod.db.hiddenAlpha end, set("hiddenAlpha"), 0, 90, 10, "%",
        { tooltip = L.xp_hiddenOpacity_tip }))

    return function() for _, r in ipairs(refreshers) do r() end end
end

function mod.PrintStatus()
    if not bar then
        ns.Print(L.xp_title .. ": " .. L.notFound)
        return
    end
    TargetAlpha()
    ns.Print(L.xp_title .. ": " .. lastReason)
end