-- UI Visibility: Personal Resource Display module
--   In combat: full opacity and bar text.
--   Out of combat while health/resource is changing: partial opacity.
--   Out of combat with full bars: hidden.
--
-- Forever hides current health and power values from addons (secret values),
-- so activity is used instead: while regenerating, the game fires health and
-- power events; when the bars are full (or rage reaches 0), they stop. The
-- wait time adapts to the rhythm of the regeneration ticks.
--
-- Performance: the display is updated on events. The fast tick only checks
-- one time value, to hide the display when a regeneration window ends.

local ADDON_NAME, ns = ...
local L = ns.Lproxy

local FRAME_NAME = "PersonalResourceDisplayFrame"
local BLIZZ_ADDON = "Blizzard_PersonalResourceDisplay"

ns.AddLocale("en", {
    tab_prd = "Resources",
    prd_title = "Personal Resource Display",
    prd_textCombat = "Bar text only in combat",
    prd_showWhen = "Show out of combat while changing:",
    prd_health = "Health",
    mana = "Mana", rage = "Rage", energy = "Energy", other = "Other resources",
    prd_opacity = "Opacity:",
    prd_inCombat = "  In combat", prd_regen = "  Regenerating", prd_full = "  Full bars",
    prd_maxDelay = "Max wait",
    prd_st_disabled = "disabled", prd_st_combat = "combat", prd_st_regen = "regenerating", prd_st_idle = "idle",
    prd_r_disabled = "module disabled", prd_r_combat = "in combat", prd_r_dead = "dead",
    prd_r_partial = "bars not full", prd_r_full = "bars full",
    prd_r_health = "health changing", prd_r_power = "%s changing", prd_r_none = "no changes",
    prd_status = "Personal Resource Display: %s (%d%%) | reason: %s | resource: %s",
    prd_debug = "health: last event %.1fs ago, visible %.1fs more | resource: last event %.1fs ago, visible %.1fs more",
})
ns.AddLocale("es", {
    tab_prd = "Recursos",
    prd_title = "Personal Resource Display",
    prd_textCombat = "Texto de las barras solo en combate",
    prd_showWhen = "Mostrar fuera de combate cuando cambia:",
    prd_health = "Vida",
    mana = "Maná", rage = "Rabia", energy = "Energía", other = "Otros recursos",
    prd_opacity = "Opacidad:",
    prd_inCombat = "  En combate", prd_regen = "  Regenerando", prd_full = "  Barras llenas",
    prd_maxDelay = "Espera máxima",
    prd_st_disabled = "desactivado", prd_st_combat = "combate", prd_st_regen = "regenerando", prd_st_idle = "en reposo",
    prd_r_disabled = "módulo desactivado", prd_r_combat = "en combate", prd_r_dead = "muerto",
    prd_r_partial = "barras incompletas", prd_r_full = "barras llenas",
    prd_r_health = "vida cambiando", prd_r_power = "%s cambiando", prd_r_none = "sin cambios",
    prd_status = "Personal Resource Display: %s (%d%%) | motivo: %s | recurso: %s",
    prd_debug = "vida: último evento hace %.1fs, visible %.1fs más | recurso: último evento hace %.1fs, visible %.1fs más",
})

local mod = {
    key = "prd", titleKey = "prd_title", tabKey = "tab_prd",
    defaults = {
        enabled = true,
        health = true,
        power = { mana = true, rage = true, energy = true, other = true },
        maxDelay = 6,
        alphaCombat = 100,
        alphaRegen = 50,
        alphaIdle = 0,
        textCombatOnly = true,
    },
}
ns.RegisterModule(mod)

local POWER_KEYS = { [0] = "mana", [1] = "rage", [3] = "energy" }
local DECAY_POWER = { [1] = true, [6] = true } -- resources that drop to 0 at rest
local MANA_PAUSE = 5.5 -- mana stops regenerating for a few seconds after casting

local prd
local applying = false
local lastReason = "-"
local dirty = true
local nextCheck = math.huge
local targetAlpha  -- opacity the display is fading toward

local track = {
    health = { last = 0, untilTime = 0 },
    power  = { last = 0, untilTime = 0 },
}

local function IsSecret(v)
    return issecretvalue and issecretvalue(v)
end

local function PowerKey()
    return POWER_KEYS[UnitPowerType("player")] or "other"
end

local function MarkActivity(t)
    local now = GetTime()
    local interval = now - t.last
    t.last = now
    local maxDelay = mod.db.maxDelay
    local timeout
    if interval < maxDelay then
        timeout = math.max(1, math.min(maxDelay, interval * 1.5 + 0.25))
    else
        timeout = maxDelay
    end
    t.untilTime = math.max(t.untilTime, now + timeout)
end

-- true/false if values are readable, nil if they are secret.
local function ExactCheck()
    local db = mod.db
    if db.health then
        local hp, hpMax = UnitHealth("player"), UnitHealthMax("player")
        if IsSecret(hp) or IsSecret(hpMax) then return nil end
        if hp < hpMax then return true end
    end
    if db.power[PowerKey()] then
        local pType = UnitPowerType("player")
        local p, pMax = UnitPower("player", pType), UnitPowerMax("player", pType)
        if IsSecret(p) or IsSecret(pMax) then return nil end
        if pMax > 0 then
            if DECAY_POWER[pType] then
                if p > 0 then return true end
            elseif p < pMax then
                return true
            end
        end
    end
    return false
end

-- Returns "disabled", "combat", "regen" or "idle".
local function GetState()
    local db = mod.db
    if not db.enabled then lastReason = L.prd_r_disabled; return "disabled" end
    if ns.IsEditMode() then lastReason = L.st_edit; return "disabled" end
    if InCombatLockdown() or UnitAffectingCombat("player") then
        lastReason = L.prd_r_combat; return "combat"
    end
    if UnitIsDeadOrGhost("player") then lastReason = L.prd_r_dead; return "idle" end

    local exact = ExactCheck()
    if exact ~= nil then
        lastReason = exact and L.prd_r_partial or L.prd_r_full
        return exact and "regen" or "idle"
    end

    local now = GetTime()
    if db.health and now < track.health.untilTime then
        lastReason = L.prd_r_health; return "regen"
    end
    if db.power[PowerKey()] and now < track.power.untilTime then
        lastReason = string.format(L.prd_r_power, L[PowerKey()]); return "regen"
    end
    lastReason = L.prd_r_none
    return "idle"
end

local function TargetAlpha(state)
    local db = mod.db
    if state == "combat" then return db.alphaCombat / 100 end
    if state == "regen" then return db.alphaRegen / 100 end
    if state == "idle" then return db.alphaIdle / 100 end
    return 1
end

-- Bar texts: every text inside the display except the Edit Mode box. The
-- list is rebuilt on the slow tick, not on every update.
local barTexts = {}
local textAlpha

local function RefreshTexts()
    wipe(barTexts)
    local function collect(frame)
        for _, region in ipairs({ frame:GetRegions() }) do
            if region:GetObjectType() == "FontString" then
                barTexts[#barTexts + 1] = region
            end
        end
        for _, child in ipairs({ frame:GetChildren() }) do
            if child ~= prd.Selection then collect(child) end
        end
    end
    collect(prd)
    textAlpha = nil -- apply again to the new list
end

local function ApplyText(state)
    local alpha = 1
    if state ~= "disabled" and state ~= "combat" and mod.db.textCombatOnly then alpha = 0 end
    if alpha == textAlpha then return end
    for _, fs in ipairs(barTexts) do fs:SetAlpha(alpha) end
    textAlpha = alpha
end

local function Apply()
    if not prd then return end
    local state = GetState()
    targetAlpha = TargetAlpha(state) -- the fast tick fades toward it
    ApplyText(state)

    -- Next moment something can change without an event: the end of a
    -- regeneration window.
    local now = GetTime()
    nextCheck = math.huge
    for _, t in pairs(track) do
        if t.untilTime > now and t.untilTime < nextCheck then nextCheck = t.untilTime end
    end
    dirty = false
end

function mod.MarkDirty() dirty = true end

function mod.OnTick(now)
    if not prd then return end
    if dirty or now >= nextCheck then Apply() end
    if targetAlpha then
        applying = true
        ns.Fade(prd, targetAlpha)
        applying = false
    end
end

function mod.OnSlowTick()
    if prd and mod.db.enabled then
        RefreshTexts()
        dirty = true
    end
end

function mod.SetEnabled(v)
    mod.db.enabled = v
    dirty = true -- when disabled, GetState returns "disabled", which restores everything
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local events = CreateFrame("Frame")

local function Attach()
    if prd then return true end
    prd = _G[FRAME_NAME]
    if not prd then return false end

    hooksecurefunc(prd, "SetAlpha", function()
        if not applying then dirty = true end
    end)
    prd:HookScript("OnShow", function() dirty = true end)
    RefreshTexts()

    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterUnitEvent("UNIT_HEALTH", "player")
    events:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
    events:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    events:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    events:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
    events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    dirty = true
    return true
end

function mod.OnAddonLoaded(name)
    if name == BLIZZ_ADDON then Attach() end
end

function mod.OnLogin()
    Attach()
end

events:SetScript("OnEvent", function(self, event)
    local now = GetTime()
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        MarkActivity(track.health)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        MarkActivity(track.power)
    elseif event == "UNIT_DISPLAYPOWER" then
        track.power.last = 0
        MarkActivity(track.power)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if PowerKey() == "mana" then
            track.power.untilTime = math.max(track.power.untilTime, now + MANA_PAUSE)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        track.health.untilTime = math.max(track.health.untilTime, now + 2)
        track.power.untilTime = math.max(track.power.untilTime, now + 2)
    elseif event == "PLAYER_ENTERING_WORLD" then
        RefreshTexts()
    end
    dirty = true
end)

---------------------------------------------------------------------------
-- Options, status and commands
---------------------------------------------------------------------------
function mod.BuildOptions(parent, y)
    local refreshers = {}
    local function add(r) refreshers[#refreshers + 1] = r end
    local function set(fn) return function(v) fn(v); dirty = true end end
    local db = function() return mod.db end

    add(ns.CreateCheck(parent, L.enabled, y,
        function() return db().enabled end, function(v) mod.SetEnabled(v) end))
    y = y - 28
    add(ns.CreateCheck(parent, L.prd_textCombat, y,
        function() return db().textCombatOnly end, set(function(v) db().textCombatOnly = v end)))
    y = y - 36

    ns.CreateHeader(parent, L.prd_showWhen, y)
    y = y - 22
    add(ns.CreateCheck(parent, L.prd_health, y,
        function() return db().health end, set(function(v) db().health = v end)))
    y = y - 28
    for _, key in ipairs({ "mana", "rage", "energy", "other" }) do
        add(ns.CreateCheck(parent, L[key], y,
            function() return db().power[key] end, set(function(v) db().power[key] = v end)))
        y = y - 28
    end

    y = y - 10
    ns.CreateHeader(parent, L.prd_opacity, y)
    y = y - 24
    for _, item in ipairs({
        { "prd_inCombat", "alphaCombat" }, { "prd_regen", "alphaRegen" }, { "prd_full", "alphaIdle" },
    }) do
        add(ns.CreateStepper(parent, L[item[1]], y,
            function() return db()[item[2]] end, set(function(v) db()[item[2]] = v end), 0, 100, 10, "%"))
        y = y - 26
    end
    y = y - 10
    add(ns.CreateStepper(parent, L.prd_maxDelay, y,
        function() return db().maxDelay end, function(v) db().maxDelay = v end, 2, 15, 1, " s"))

    return function() for _, r in ipairs(refreshers) do r() end end
end

local STATE_KEYS = { disabled = "prd_st_disabled", combat = "prd_st_combat", regen = "prd_st_regen", idle = "prd_st_idle" }

function mod.PrintStatus()
    if not prd then
        ns.Print(L.prd_title .. ": " .. L.notFound)
        return
    end
    local state = GetState()
    ns.Print(string.format(L.prd_status, L[STATE_KEYS[state]],
        math.floor(TargetAlpha(state) * 100 + 0.5), lastReason, L[PowerKey()]))
end

function mod.Command(cmd)
    if cmd == "debug" then
        local now = GetTime()
        ns.Print(string.format(L.prd_debug,
            now - track.health.last, math.max(0, track.health.untilTime - now),
            now - track.power.last, math.max(0, track.power.untilTime - now)))
        return true
    end
    return false
end
