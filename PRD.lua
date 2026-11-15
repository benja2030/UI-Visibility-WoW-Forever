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
    prd_secOpacity = "Opacity",
    prd_secTracked = "Counts as regenerating",
    prd_secText = "Bar text",
    prd_secTiming = "Timing",
    prd_textCombat = "Only in combat",
    prd_textCombat_tip = "Hides the health and resource numbers out of combat. Turn on Show Bar Text in Edit Mode for the numbers to show at all.",
    prd_health = "Health",
    rage_tip = "Rage drains to zero out of combat, so it counts while it's draining.",
    other_tip = "Runic power, focus and other resources.",
    mana = "Mana", rage = "Rage", energy = "Energy", other = "Other resources",
    prd_inCombat = "In combat", prd_regen = "Regenerating", prd_full = "Full bars",
    prd_maxDelay = "Initial wait",
    prd_maxDelay_tip = "How long to wait after the last change before hiding, until the addon learns how often you regenerate.",
    prd_margin = "Margin",
    prd_margin_tip = "Extra time after the expected next regeneration tick. Raise it if the display hides while still regenerating; lower it if it takes too long to hide.",
    prd_st_disabled = "disabled", prd_st_combat = "combat", prd_st_regen = "regenerating", prd_st_idle = "idle",
    prd_r_disabled = "module disabled", prd_r_combat = "in combat", prd_r_dead = "dead",
    prd_r_partial = "bars not full", prd_r_full = "bars full",
    prd_r_health = "health changing", prd_r_power = "%s changing", prd_r_none = "no changes",
    prd_status = "Personal Resource Display: %s (%d%%) | reason: %s | resource: %s",
    prd_debug = "health: last event %.1fs ago, visible %.1fs more | resource: last event %.1fs ago, visible %.1fs more",
    prd_method = "detection: %s | health rhythm: %s (+%.1fs learned) | resource rhythm: %s (+%.1fs learned)",
    prd_m_values = "exact (values)", prd_m_bars = "exact (bar fill)", prd_m_activity = "activity",
    prd_unknown = "unknown",
})
ns.AddLocale("es", {
    tab_prd = "Recursos",
    prd_title = "Personal Resource Display",
    prd_secOpacity = "Opacidad",
    prd_secTracked = "Cuenta como regeneración",
    prd_secText = "Texto de las barras",
    prd_secTiming = "Tiempos",
    prd_textCombat = "Solo en combate",
    prd_textCombat_tip = "Oculta los números de vida y recurso fuera de combate. Activa Show Bar Text en el Modo Edición para que los números se muestren.",
    prd_health = "Vida",
    rage_tip = "La rabia baja a cero fuera de combate, así que cuenta mientras baja.",
    other_tip = "Poder rúnico, enfoque y otros recursos.",
    mana = "Maná", rage = "Rabia", energy = "Energía", other = "Otros recursos",
    prd_inCombat = "En combate", prd_regen = "Regenerando", prd_full = "Barras llenas",
    prd_maxDelay = "Espera inicial",
    prd_maxDelay_tip = "Cuánto esperar tras el último cambio antes de ocultar, hasta que el addon aprenda cada cuánto regeneras.",
    prd_margin = "Margen",
    prd_margin_tip = "Tiempo extra después del siguiente pulso de regeneración esperado. Súbelo si se oculta mientras aún regeneras; bájalo si tarda demasiado en ocultarse.",
    prd_st_disabled = "desactivado", prd_st_combat = "combate", prd_st_regen = "regenerando", prd_st_idle = "en reposo",
    prd_r_disabled = "módulo desactivado", prd_r_combat = "en combate", prd_r_dead = "muerto",
    prd_r_partial = "barras incompletas", prd_r_full = "barras llenas",
    prd_r_health = "vida cambiando", prd_r_power = "%s cambiando", prd_r_none = "sin cambios",
    prd_status = "Personal Resource Display: %s (%d%%) | motivo: %s | recurso: %s",
    prd_debug = "vida: último evento hace %.1fs, visible %.1fs más | recurso: último evento hace %.1fs, visible %.1fs más",
    prd_method = "detección: %s | ritmo de vida: %s (+%.1fs aprendido) | ritmo de recurso: %s (+%.1fs aprendido)",
    prd_m_values = "exacta (valores)", prd_m_bars = "exacta (relleno de barra)", prd_m_activity = "actividad",
    prd_unknown = "desconocido",
})

local mod = {
    key = "prd", titleKey = "prd_title", tabKey = "tab_prd",
    defaults = {
        enabled = true,
        health = true,
        power = { mana = true, rage = true, energy = true, other = true },
        maxDelay = 6,
        margin = 3, -- tenths of a second added after the expected next pulse
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
    health = { last = 0, untilTime = 0, intervals = {}, learned = 0 },
    power  = { last = 0, untilTime = 0, intervals = {}, learned = 0 },
}
local lastMethod = "prd_m_activity"

local function IsSecret(v)
    return issecretvalue and issecretvalue(v)
end

local function PowerKey()
    return POWER_KEYS[UnitPowerType("player")] or "other"
end

-- Regeneration comes in pulses. The wait after the last pulse is the usual
-- interval between pulses (the median of the last three, so one odd interval
-- doesn't change it) plus a small margin set by the user. The "Initial wait"
-- setting is only used until the rhythm is known.
local RHYTHM_LIMIT = 10   -- intervals longer than this mean regeneration stopped
local DUPLICATE = 0.05    -- events this close together belong to the same pulse
local LEARN_MAX = 1.5     -- most extra wait the addon can learn (seconds)
local LEARN_STEP = 0.1    -- extra added on top of a late pulse's delay
local LEARN_DECAY = 0.97  -- each on-time pulse keeps 97% of the learned wait

local function Rhythm(t)
    local n = #t.intervals
    if n == 0 then return 0 end
    local sorted = {}
    for i, v in ipairs(t.intervals) do sorted[i] = v end
    table.sort(sorted)
    if n % 2 == 1 then return sorted[(n + 1) / 2] end
    return (sorted[n / 2] + sorted[n / 2 + 1]) / 2
end

-- Learning: if a pulse arrives after the wait ran out (so the display already
-- hid while still regenerating), the delay is learned and added to the next
-- waits. Pulses that arrive on time slowly shrink what was learned.
local function MarkActivity(t)
    local now = GetTime()
    local interval = now - t.last
    local previousUntil = t.untilTime
    t.last = now
    if interval > RHYTHM_LIMIT then
        wipe(t.intervals) -- a new regeneration started
    elseif interval > DUPLICATE then
        local rhythm = Rhythm(t)
        if rhythm > 0 and now > previousUntil and interval < rhythm * 2
            and not InCombatLockdown() then
            -- Late pulse: the display hid too early.
            t.learned = math.min(LEARN_MAX, t.learned + (now - previousUntil) + LEARN_STEP)
        else
            t.learned = t.learned * LEARN_DECAY
        end
        table.insert(t.intervals, interval)
        if #t.intervals > 3 then table.remove(t.intervals, 1) end
    end
    local rhythm = Rhythm(t)
    local timeout
    if rhythm > 0 then
        timeout = math.min(RHYTHM_LIMIT, rhythm * 1.05 + mod.db.margin / 10 + t.learned)
    else
        timeout = mod.db.maxDelay
    end
    t.untilTime = math.max(t.untilTime, now + timeout)
end

-- Fraction (0 to 1) of a status bar that is filled, read from the size of its
-- fill on screen. nil if the game keeps that secret too.
local function BarFill(bar)
    if not bar or not bar.GetStatusBarTexture then return nil end
    local ok, fill = pcall(function()
        local texture = bar:GetStatusBarTexture()
        if not texture then return nil end
        local barWidth, fillWidth = bar:GetWidth(), texture:GetWidth()
        if IsSecret(barWidth) or IsSecret(fillWidth) then return nil end
        if barWidth <= 0 then return nil end
        local shown = texture:IsShown()
        if IsSecret(shown) then return nil end
        if not shown then return 0 end
        return fillWidth / barWidth
    end)
    if ok then return fill end
    return nil
end

local function HealthBar()
    return prd and prd.HealthBarsContainer and prd.HealthBarsContainer.healthBar
end

local function PowerBar()
    return prd and prd.PowerBar
end

-- Second exact method: true/false from the bars' fill, nil if not readable.
local function BarCheck()
    local db = mod.db
    if db.health then
        local fill = BarFill(HealthBar())
        if fill == nil then return nil end
        if fill < 0.995 then return true end
    end
    if db.power[PowerKey()] then
        local bar = PowerBar()
        if bar and bar:IsShown() then
            local fill = BarFill(bar)
            if fill == nil then return nil end
            if DECAY_POWER[UnitPowerType("player")] then
                if fill > 0.005 then return true end
            elseif fill < 0.995 then
                return true
            end
        end
    end
    return false
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
        lastMethod = "prd_m_values"
    else
        exact = BarCheck()
        if exact ~= nil then lastMethod = "prd_m_bars" end
    end
    if exact ~= nil then
        lastReason = exact and L.prd_r_partial or L.prd_r_full
        return exact and "regen" or "idle"
    end
    lastMethod = "prd_m_activity"

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
    -- regeneration window. With bar detection the bar can finish filling
    -- between events, so it's checked again shortly while not full.
    local now = GetTime()
    nextCheck = math.huge
    if lastMethod == "prd_m_bars" and state == "regen" then nextCheck = now + 0.2 end
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
    local function tip(key)
        local t = L[key .. "_tip"]
        if t ~= key .. "_tip" then return t end
    end

    add(ns.CreateCheck(parent, L.enabled, y,
        function() return db().enabled end, function(v) mod.SetEnabled(v) end))
    y = y - 40

    ns.CreateSection(parent, L.prd_secOpacity, y)
    y = y - 32
    for _, item in ipairs({
        { "prd_inCombat", "alphaCombat" }, { "prd_regen", "alphaRegen" }, { "prd_full", "alphaIdle" },
    }) do
        add(ns.CreateStepper(parent, L[item[1]], y,
            function() return db()[item[2]] end, set(function(v) db()[item[2]] = v end), 0, 100, 10, "%"))
        y = y - 28
    end
    y = y - 12

    ns.CreateSection(parent, L.prd_secTracked, y)
    y = y - 32
    local items = {
        { "prd_health", function() return db().health end, function(v) db().health = v end },
    }
    for _, key in ipairs({ "mana", "rage", "energy", "other" }) do
        items[#items + 1] = { key,
            function() return db().power[key] end, function(v) db().power[key] = v end }
    end
    for i, item in ipairs(items) do
        local col = (i - 1) % 2
        add(ns.CreateCheck(parent, L[item[1]], y, item[2], set(item[3]),
            { x = col == 0 and 16 or 216, width = 160, tooltip = tip(item[1]) }))
        if col == 1 or i == #items then y = y - 28 end
    end
    y = y - 12

    ns.CreateSection(parent, L.prd_secText, y)
    y = y - 32
    add(ns.CreateCheck(parent, L.prd_textCombat, y,
        function() return db().textCombatOnly end, set(function(v) db().textCombatOnly = v end),
        { tooltip = L.prd_textCombat_tip }))
    y = y - 40

    ns.CreateSection(parent, L.prd_secTiming, y)
    y = y - 32
    add(ns.CreateStepper(parent, L.prd_maxDelay, y,
        function() return db().maxDelay end, function(v) db().maxDelay = v end, 2, 15, 1, " s",
        { tooltip = L.prd_maxDelay_tip }))
    y = y - 28
    -- Stored in tenths so the stepper works with whole numbers.
    add(ns.CreateStepper(parent, L.prd_margin, y,
        function() return db().margin end, function(v) db().margin = v end, 0, 10, 1,
        function(v) return string.format("%.1f s", v / 10) end,
        { tooltip = L.prd_margin_tip }))

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

local function RhythmText(t)
    local rhythm = Rhythm(t)
    if rhythm <= 0 then return L.prd_unknown end
    return string.format("%.1fs", rhythm)
end

function mod.Command(cmd)
    if cmd == "debug" then
        local now = GetTime()
        if prd then GetState() end -- updates the detection method
        ns.Print(string.format(L.prd_debug,
            now - track.health.last, math.max(0, track.health.untilTime - now),
            now - track.power.last, math.max(0, track.power.untilTime - now)))
        ns.Print(string.format(L.prd_method, L[lastMethod],
            RhythmText(track.health), track.health.learned,
            RhythmText(track.power), track.power.learned))
        return true
    end
    return false
end