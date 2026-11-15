-- UI Visibility: names module
-- Makes the name of the character under the mouse bigger.
--
-- How it works: names shown by friendly "names only" nameplates are interface
-- text, but the game ignores changes to their size. Addons can hide them,
-- though, and can place their own text on a nameplate. So while the mouse is
-- over a character with a nameplate, the module hides that nameplate's name
-- and draws its own copy in the same place, with the same font and color,
-- only bigger. When the mouse leaves, the copy goes away and the original
-- comes back. Only the hovered name grows.
--
-- Characters without a nameplate (for example out of nameplate range, or
-- friendly nameplates turned off) can optionally use the old method: raise
-- the "Minimum character name size" game setting (WorldTextMinSize) while
-- hovering. That one makes every name on screen grow, so it's off by default.
--
-- Safety: when the old method is used, the player's own value is saved and
-- put back on logout, or on the next login if the game closed while raised.

local ADDON_NAME, ns = ...
local L = ns.Lproxy

local CVAR = "WorldTextMinSize"
local LINGER = 0.15 -- seconds a name stays big after the mouse leaves

ns.AddLocale("en", {
    tab_names = "Names",
    nm_title = "Character Names",
    nm_size = "Name size on hover",
    nm_who = "Grow names when hovering:",
    nm_players = "Players",
    nm_npcs = "NPCs",
    nm_enemies = "Enemies",
    nm_worldOnly = "Only when hovering characters in the world",
    nm_fallback = "Without a nameplate, grow every name instead",
    nm_fallbackSize = "Size for every name",
    nm_note = "Turn on friendly nameplates (Shift+V) and set them to show names only: then only the hovered name grows. Names without a nameplate stay as they are, unless the option above is on.",
    nm_st_disabled = "module disabled",
    nm_st_plate = "showing %s bigger",
    nm_st_all = "every name bigger (hovering %s, no nameplate)",
    nm_st_idle = "waiting for the mouse",
    nm_noCVar = "this game version doesn't have the WorldTextMinSize setting, so \"grow every name\" can't work.",
})
ns.AddLocale("es", {
    tab_names = "Nombres",
    nm_title = "Nombres de personajes",
    nm_size = "Tamaño al pasar el mouse",
    nm_who = "Agrandar el nombre al apuntar a:",
    nm_players = "Jugadores",
    nm_npcs = "PNJ",
    nm_enemies = "Enemigos",
    nm_worldOnly = "Solo al apuntar personajes en el mundo",
    nm_fallback = "Sin placa, agrandar todos los nombres",
    nm_fallbackSize = "Tamaño para todos los nombres",
    nm_note = "Activa las placas aliadas (Shift+V) y configúralas para mostrar solo nombres: así crece solo el nombre que apuntas. Los nombres sin placa quedan igual, salvo que actives la opción de arriba.",
    nm_st_disabled = "módulo desactivado",
    nm_st_plate = "mostrando a %s más grande",
    nm_st_all = "todos los nombres grandes (apuntando a %s, sin placa)",
    nm_st_idle = "esperando el mouse",
    nm_noCVar = "esta versión del juego no tiene el ajuste WorldTextMinSize, así que \"agrandar todos los nombres\" no puede funcionar.",
})

local mod = {
    key = "names", titleKey = "nm_title", tabKey = "tab_names",
    defaults = {
        enabled = true,
        size = 18,
        players = true,
        npcs = true,
        enemies = true,
        worldOnly = true,
        fallbackAll = false,
        fallbackSize = 24,
        savedSize = nil, -- the player's own WorldTextMinSize while raised
    },
}
ns.RegisterModule(mod)

local cvarAvailable = false

-- State of the current hover.
local activeName      -- the nameplate's original name text
local activeMode      -- "plate", "all" or nil
local hoveredLabel = ""
local hoverUntil = 0

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function Yes(value)
    if ns.IsSecret(value) then return true end
    return value and true or false
end

-- True if the mouse is over the 3D world, not over an interface frame.
local function MouseOverWorld()
    local ok, result = pcall(function()
        if GetMouseFoci then
            local focus = GetMouseFoci()[1]
            return focus == nil or focus == WorldFrame
        elseif GetMouseFocus then
            local focus = GetMouseFocus()
            return focus == nil or focus == WorldFrame
        end
        return true
    end)
    return not ok or result
end

-- True if the character under the mouse passes the filters.
local function WantsHovered()
    local db = mod.db
    if not Yes(UnitExists("mouseover")) then return false end
    if Yes(UnitIsUnit("mouseover", "player")) then return false end
    if db.worldOnly and not MouseOverWorld() then return false end
    if not db.enemies then
        local canAttack = UnitCanAttack("player", "mouseover")
        if not ns.IsSecret(canAttack) and canAttack then return false end
    end
    local isPlayer = UnitIsPlayer("mouseover")
    if ns.IsSecret(isPlayer) then return db.players or db.npcs end
    if isPlayer then return db.players end
    return db.npcs
end

-- The name text of the hovered character's nameplate, or nil.
local function HoveredPlateName()
    local ok, name = pcall(function()
        local plate = C_NamePlate.GetNamePlateForUnit("mouseover")
        if not plate or (plate.IsForbidden and plate:IsForbidden()) then return nil end
        local frame = plate.UnitFrame
        local text = frame and (frame.name
            or (frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar
                and frame.HealthBarsContainer.healthBar.unitNameFontString))
        if not text or (text.IsForbidden and text:IsForbidden()) then return nil end
        local shown = text:IsShown()
        if ns.IsSecret(shown) or not shown then return nil end
        return text
    end)
    if ok then return name end
    return nil
end

---------------------------------------------------------------------------
-- Bigger copy of a nameplate name
---------------------------------------------------------------------------
-- The copy lives on its own frame, low in the drawing order, so windows and
-- bars still cover it like they cover nameplates.
local holder = CreateFrame("Frame", nil, UIParent)
holder:SetFrameStrata("BACKGROUND")
holder:SetAllPoints(UIParent)
local copy = holder:CreateFontString(nil, "OVERLAY")
copy:Hide()

local function ShowCopy(original)
    local font, _, flags = original:GetFont()
    if ns.IsSecret(font) or not font then font = STANDARD_TEXT_FONT end
    -- Keep the outline, drop flags addons can't use (like SLUG).
    local outline = "OUTLINE"
    if not ns.IsSecret(flags) and type(flags) == "string" and flags:find("THICK") then
        outline = "THICKOUTLINE"
    end
    if not copy:SetFont(font, mod.db.size, outline) then
        copy:SetFont(STANDARD_TEXT_FONT, mod.db.size, outline)
    end
    copy:SetShadowOffset(1, -1)
    copy:SetShadowColor(0, 0, 0, 1)

    local r, g, b = original:GetTextColor()
    if ns.IsSecret(r) or ns.IsSecret(g) or ns.IsSecret(b) or not r then r, g, b = 1, 1, 1 end
    copy:SetTextColor(r, g, b)

    local text = original:GetText()
    if ns.IsSecret(text) then
        -- Can't be read, but it can still be displayed.
        pcall(copy.SetText, copy, text)
    else
        copy:SetText(text or "")
    end

    -- Bottom to bottom: the bigger name grows upward, away from the head.
    copy:ClearAllPoints()
    copy:SetPoint("BOTTOM", original, "BOTTOM", 0, 0)
    copy:Show()
    original:SetAlpha(0)
end

local function HideCopy()
    copy:Hide()
    if activeName then pcall(activeName.SetAlpha, activeName, 1) end
end

---------------------------------------------------------------------------
-- "Every name" fallback (WorldTextMinSize)
---------------------------------------------------------------------------
local function SetMinSize(value)
    pcall(SetCVar, CVAR, tostring(value))
end

local function RaiseAll()
    if not cvarAvailable then return false end
    if mod.db.savedSize == nil then
        mod.db.savedSize = tonumber(GetCVar(CVAR)) or 0
    end
    if mod.db.fallbackSize > mod.db.savedSize then SetMinSize(mod.db.fallbackSize) end
    return true
end

local function RestoreAll()
    if mod.db.savedSize ~= nil then
        SetMinSize(mod.db.savedSize)
        mod.db.savedSize = nil
    end
end

---------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------
local function Stop()
    if activeMode == "plate" then HideCopy() end
    if activeMode == "all" then RestoreAll() end
    activeName, activeMode = nil, nil
end
mod.Stop = Stop

function mod.OnTick(now)
    if not mod.db.enabled then
        if activeMode then Stop() end
        return
    end

    if not WantsHovered() then
        if activeMode and now >= hoverUntil then Stop() end
        return
    end
    hoverUntil = now + LINGER

    local plateName = HoveredPlateName()
    if plateName then
        if activeMode == "plate" and activeName == plateName then
            -- Same character: keep the original hidden in case the game
            -- showed it again.
            if plateName:GetAlpha() ~= 0 then plateName:SetAlpha(0) end
            return
        end
        Stop()
        activeName, activeMode = plateName, "plate"
        local label = UnitName("mouseover")
        hoveredLabel = (not ns.IsSecret(label) and label) or "?"
        ShowCopy(plateName)
        return
    end

    -- No nameplate for this character.
    if mod.db.fallbackAll then
        if activeMode ~= "all" then
            Stop()
            if RaiseAll() then
                activeMode = "all"
                local label = UnitName("mouseover")
                hoveredLabel = (not ns.IsSecret(label) and label) or "?"
            end
        end
    elseif activeMode then
        Stop()
    end
end

function mod.SetEnabled(v)
    mod.db.enabled = v
    if not v then Stop() end
end

-- A nameplate given to another character: drop the copy at once.
local events = CreateFrame("Frame")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGOUT" then
        if mod.db then RestoreAll() end
        return
    end
    if activeMode == "plate" then Stop() end
end)

function mod.OnLogin()
    cvarAvailable = GetCVar(CVAR) ~= nil
    -- The game closed while every name was raised: put the value back.
    if mod.db.savedSize ~= nil then
        if cvarAvailable then SetMinSize(mod.db.savedSize) end
        mod.db.savedSize = nil
    end
end

---------------------------------------------------------------------------
-- Options and status
---------------------------------------------------------------------------
function mod.BuildOptions(parent, y)
    local refreshers = {}
    local function add(r) refreshers[#refreshers + 1] = r end
    local function set(key) return function(v) mod.db[key] = v; Stop() end end

    add(ns.CreateCheck(parent, L.enabled, y,
        function() return mod.db.enabled end, function(v) mod.SetEnabled(v) end))
    y = y - 36

    add(ns.CreateSlider(parent, L.nm_size, y,
        function() return mod.db.size end, set("size"), 10, 40,
        function(v) return tostring(math.floor(v + 0.5)) end))
    y = y - 36

    ns.CreateHeader(parent, L.nm_who, y)
    y = y - 22
    for _, item in ipairs({ { "nm_players", "players" }, { "nm_npcs", "npcs" }, { "nm_enemies", "enemies" } }) do
        add(ns.CreateCheck(parent, L[item[1]], y,
            function() return mod.db[item[2]] end, set(item[2])))
        y = y - 28
    end
    y = y - 8
    add(ns.CreateCheck(parent, L.nm_worldOnly, y,
        function() return mod.db.worldOnly end, set("worldOnly")))
    y = y - 36

    add(ns.CreateCheck(parent, L.nm_fallback, y,
        function() return mod.db.fallbackAll end, set("fallbackAll")))
    y = y - 32
    add(ns.CreateSlider(parent, L.nm_fallbackSize, y,
        function() return mod.db.fallbackSize end, set("fallbackSize"), 1, 64,
        function(v) return tostring(math.floor(v + 0.5)) end))
    y = y - 40
    ns.CreateNote(parent, L.nm_note, y)

    return function() for _, r in ipairs(refreshers) do r() end end
end

function mod.PrintStatus()
    local state
    if not mod.db.enabled then
        state = L.nm_st_disabled
    elseif activeMode == "plate" then
        state = string.format(L.nm_st_plate, hoveredLabel)
    elseif activeMode == "all" then
        state = string.format(L.nm_st_all, hoveredLabel)
    else
        state = L.nm_st_idle
    end
    ns.Print(L.nm_title .. ": " .. state)
    if mod.db.fallbackAll and not cvarAvailable then ns.Print(L.nm_noCVar) end
end