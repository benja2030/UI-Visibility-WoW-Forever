-- UI Visibility: names module
-- Makes the names above characters' heads bigger while the mouse is over a
-- player or NPC.
--
-- Those names are drawn by the game engine, not by interface frames, so an
-- addon can't resize one name on its own. What it can change is the setting
-- behind Accessibility > "Minimum character name size" (the WorldTextMinSize
-- game variable). This module raises it while the mouse is over a character
-- and puts the player's own value back when the mouse leaves. While it's
-- raised, every name on screen grows, not only the hovered one.
--
-- Safety: the player's value is saved before raising it. If the game closes
-- while it's raised, it's put back on logout, or on the next login.
--
-- Performance: the fast tick only checks the mouseover unit while the module
-- is enabled. Nothing is changed unless the hovered character changes.

local ADDON_NAME, ns = ...
local L = ns.Lproxy

local CVAR = "WorldTextMinSize"
local MAX_SIZE = 64
local LINGER = 0.15 -- seconds the names stay big after the mouse leaves

ns.AddLocale("en", {
    tab_names = "Names",
    nm_title = "Character Names",
    nm_size = "Name size on hover",
    nm_players = "Players",
    nm_npcs = "NPCs",
    nm_enemies = "Enemies",
    nm_self = "Your own character",
    nm_worldOnly = "Only when hovering characters in the world",
    nm_who = "Grow names when hovering:",
    nm_note = "These names are drawn by the game, so while you hover a character every name on screen grows, not only theirs. Your normal size is the one set in Accessibility > Minimum character name size.",
    nm_status = "Character names: %s | normal size: %s | size on hover: %d",
    nm_st_raised = "big (hovering %s)",
    nm_st_normal = "normal",
    nm_st_disabled = "module disabled",
    nm_noCVar = "this game version doesn't have the WorldTextMinSize setting, so the names module can't work.",
})
ns.AddLocale("es", {
    tab_names = "Nombres",
    nm_title = "Nombres de personajes",
    nm_size = "Tamaño al pasar el mouse",
    nm_players = "Jugadores",
    nm_npcs = "PNJ",
    nm_enemies = "Enemigos",
    nm_self = "Tu propio personaje",
    nm_worldOnly = "Solo al apuntar personajes en el mundo",
    nm_who = "Agrandar nombres al apuntar a:",
    nm_note = "El juego dibuja estos nombres, así que mientras apuntas a un personaje crecen todos los nombres en pantalla, no solo el suyo. Tu tamaño normal es el de Accesibilidad > Tamaño mínimo del nombre del personaje.",
    nm_status = "Nombres de personajes: %s | tamaño normal: %s | tamaño al apuntar: %d",
    nm_st_raised = "grandes (apuntando a %s)",
    nm_st_normal = "normales",
    nm_st_disabled = "módulo desactivado",
    nm_noCVar = "esta versión del juego no tiene el ajuste WorldTextMinSize, así que el módulo de nombres no puede funcionar.",
})

local mod = {
    key = "names", titleKey = "nm_title", tabKey = "tab_names",
    defaults = {
        enabled = true,
        size = 24,
        players = true,
        npcs = true,
        enemies = true,
        self = false,
        worldOnly = true,
        -- Set while the size is raised: the player's own value, to put back.
        savedSize = nil,
    },
}
ns.RegisterModule(mod)

local available = false
local raised = false
local hoverUntil = 0
local hoveredName = ""

-- Reads a yes/no answer that might be secret. Secret answers count as "yes",
-- so the filter never blocks a character just because the game hid the answer.
local function Yes(value)
    if ns.IsSecret(value) then return true end
    return value and true or false
end

-- True if the mouse is over the 3D world, not over an interface frame (so
-- hovering a party frame or the target frame doesn't count).
local function MouseOverWorld()
    local ok, result = pcall(function()
        if GetMouseFoci then
            local foci = GetMouseFoci()
            local focus = foci and foci[1]
            return focus == nil or focus == WorldFrame
        elseif GetMouseFocus then
            local focus = GetMouseFocus()
            return focus == nil or focus == WorldFrame
        end
        return true
    end)
    if not ok then return true end
    return result
end

-- True if the character under the mouse should make the names grow.
local function ShouldRaise()
    local db = mod.db
    if not db.enabled then return false end
    if not Yes(UnitExists("mouseover")) then return false end
    if db.worldOnly and not MouseOverWorld() then return false end

    if Yes(UnitIsUnit("mouseover", "player")) then return db.self end

    if not db.enemies then
        local canAttack = UnitCanAttack("player", "mouseover")
        if not ns.IsSecret(canAttack) and canAttack then return false end
    end

    local isPlayer = UnitIsPlayer("mouseover")
    if ns.IsSecret(isPlayer) then return db.players or db.npcs end
    if isPlayer then return db.players end
    return db.npcs
end

local function SetSize(value)
    pcall(SetCVar, CVAR, tostring(value))
end

local function Raise()
    if raised then return end
    local current = tonumber(GetCVar(CVAR)) or 0
    mod.db.savedSize = current
    raised = true
    if mod.db.size > current then SetSize(mod.db.size) end
end

local function Restore()
    if not raised then return end
    raised = false
    if mod.db.savedSize then SetSize(mod.db.savedSize) end
    mod.db.savedSize = nil
end
mod.Restore = Restore

function mod.OnTick(now)
    if not available or not mod.db.enabled then
        if raised then Restore() end
        return
    end
    if ShouldRaise() then
        hoverUntil = now + LINGER
        if not raised then
            local name = UnitName("mouseover")
            hoveredName = (not ns.IsSecret(name) and name) or "?"
            Raise()
        end
    elseif raised and now >= hoverUntil then
        Restore()
    end
end

function mod.SetEnabled(v)
    mod.db.enabled = v
    if not v then Restore() end
end

function mod.OnLogin()
    available = GetCVar(CVAR) ~= nil
    if not available then
        ns.Print(L.nm_noCVar)
        return
    end
    -- The game closed while the names were raised: put the player's value back.
    if mod.db.savedSize then
        SetSize(mod.db.savedSize)
        mod.db.savedSize = nil
    end
end

-- Put the value back before the settings are saved on logout or reload.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function()
    if raised and mod.db and mod.db.savedSize then
        SetSize(mod.db.savedSize)
        mod.db.savedSize = nil
        raised = false
    end
end)

function mod.BuildOptions(parent, y)
    local refreshers = {}
    local function add(r) refreshers[#refreshers + 1] = r end
    local function set(key) return function(v) mod.db[key] = v; Restore() end end

    add(ns.CreateCheck(parent, L.enabled, y,
        function() return mod.db.enabled end, function(v) mod.SetEnabled(v) end))
    y = y - 36

    add(ns.CreateSlider(parent, L.nm_size, y,
        function() return mod.db.size end, set("size"), 1, MAX_SIZE,
        function(v) return tostring(math.floor(v + 0.5)) end))
    y = y - 36

    ns.CreateHeader(parent, L.nm_who, y)
    y = y - 22
    for _, item in ipairs({
        { "nm_players", "players" }, { "nm_npcs", "npcs" },
        { "nm_enemies", "enemies" }, { "nm_self", "self" },
    }) do
        add(ns.CreateCheck(parent, L[item[1]], y,
            function() return mod.db[item[2]] end, set(item[2])))
        y = y - 28
    end
    y = y - 8
    add(ns.CreateCheck(parent, L.nm_worldOnly, y,
        function() return mod.db.worldOnly end, set("worldOnly")))
    y = y - 40
    ns.CreateNote(parent, L.nm_note, y)

    return function() for _, r in ipairs(refreshers) do r() end end
end

function mod.PrintStatus()
    if not available then ns.Print(L.nm_noCVar); return end
    local state
    if not mod.db.enabled then
        state = L.nm_st_disabled
    elseif raised then
        state = string.format(L.nm_st_raised, hoveredName)
    else
        state = L.nm_st_normal
    end
    local normal = raised and mod.db.savedSize or GetCVar(CVAR)
    ns.Print(string.format(L.nm_status, state, tostring(normal), mod.db.size))
end