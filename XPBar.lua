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
    xp_hover = "Show on mouse hover",
    xp_onGain = "Show after gaining experience",
    xp_duration = "Time shown",
    xp_hiddenOpacity = "Opacity when hidden",
    xp_r_edit = "Edit Mode", xp_r_disabled = "module disabled", xp_r_hover = "mouse over the bar",
    xp_r_gain = "experience gained (%.1fs left)", xp_r_hidden = "hidden",
})
ns.AddLocale("es", {
    tab_xp = "Barra XP",
    xp_title = "Barra de experiencia",
    xp_hover = "Mostrar al pasar el mouse",
    xp_onGain = "Mostrar al ganar experiencia",
    xp_duration = "Tiempo visible",
    xp_hiddenOpacity = "Opacidad oculta",
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
    y = y - 36
    add(ns.CreateCheck(parent, L.xp_hover, y, function() return mod.db.hover end, set("hover")))
    y = y - 28
    add(ns.CreateCheck(parent, L.xp_onGain, y, function() return mod.db.showOnGain end, set("showOnGain")))
    y = y - 40
    add(ns.CreateStepper(parent, L.xp_duration, y,
        function() return mod.db.gainDuration end, set("gainDuration"), 1, 30, 1, " s"))
    y = y - 28
    add(ns.CreateStepper(parent, L.xp_hiddenOpacity, y,
        function() return mod.db.hiddenAlpha end, set("hiddenAlpha"), 0, 90, 10, "%"))

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
