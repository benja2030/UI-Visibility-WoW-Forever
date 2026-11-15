-- UI Visibility: names module
-- Helps read the name of the character under the mouse, at any distance.
--
-- The names above characters' heads are drawn by the game engine, and addons
-- can't know where a character's head is on screen. But while you hover a
-- character, the cursor is on top of it, and addons do know where the cursor
-- is. So this module offers two things:
--   * Name at the cursor: a big copy of the hovered character's name, in the
--     game's name colors, follows the cursor while you hover them.
--   * Tooltip at the cursor: the tooltip shows up next to the cursor instead
--     of in the corner, optionally bigger.
--
-- The game's own name above the head can't be hidden for one character only
-- (only for every player or every NPC at once), so both names show while you
-- hover.
--
-- Performance: the name follows the cursor with its own OnUpdate, which only
-- runs while the name is on screen.

local ADDON_NAME, ns = ...
local L = ns.Lproxy

local LINGER = 0.15 -- seconds the name stays after the mouse leaves
local POSITIONS = { "above", "right", "below" }

ns.AddLocale("en", {
    tab_names = "Names",
    nm_title = "Character Names",
    nm_cursorName = "Show the hovered character's name at the cursor",
    nm_size = "Name size",
    nm_position = "Position",
    above = "Above the cursor", right = "Right of the cursor", below = "Below the cursor",
    nm_skipPlates = "Skip characters close enough to have a nameplate",
    nm_who = "Show it when hovering:",
    nm_players = "Players",
    nm_npcs = "NPCs",
    nm_enemies = "Enemies",
    nm_worldOnly = "Only when hovering characters in the world",
    nm_delay = "Show delay",
    nm_hideCombat = "Don't show it in combat",
    nm_hideInstances = "Don't show it in dungeons, raids and battlegrounds",
    nm_tooltipHeader = "Tooltip:",
    nm_tooltipCursor = "Show the tooltip next to the cursor",
    nm_tooltipScale = "Tooltip size",
    nm_note = "The show delay applies to both the name and the tooltip of characters and objects in the world. The game doesn't let addons know where a character's head is on screen, so the name is shown at the cursor.",
    nm_st_disabled = "module disabled",
    nm_st_showing = "showing %s at the cursor",
    nm_st_idle = "waiting for the mouse",
})
ns.AddLocale("es", {
    tab_names = "Nombres",
    nm_title = "Nombres de personajes",
    nm_cursorName = "Mostrar el nombre del personaje apuntado junto al cursor",
    nm_size = "Tamaño del nombre",
    nm_position = "Posición",
    above = "Sobre el cursor", right = "A la derecha", below = "Bajo el cursor",
    nm_skipPlates = "Omitir personajes cercanos que ya tienen placa",
    nm_who = "Mostrarlo al apuntar a:",
    nm_players = "Jugadores",
    nm_npcs = "PNJ",
    nm_enemies = "Enemigos",
    nm_worldOnly = "Solo al apuntar personajes en el mundo",
    nm_delay = "Retraso",
    nm_hideCombat = "No mostrarlo en combate",
    nm_hideInstances = "No mostrarlo en mazmorras, bandas y campos de batalla",
    nm_tooltipHeader = "Tooltip:",
    nm_tooltipCursor = "Mostrar el tooltip junto al cursor",
    nm_tooltipScale = "Tamaño del tooltip",
    nm_note = "El retraso se aplica al nombre y al tooltip de personajes y objetos del mundo. El juego no deja a los addons saber dónde está la cabeza de un personaje en la pantalla, así que el nombre se muestra junto al cursor.",
    nm_st_disabled = "módulo desactivado",
    nm_st_showing = "mostrando a %s junto al cursor",
    nm_st_idle = "esperando el mouse",
})

local mod = {
    key = "names", titleKey = "nm_title", tabKey = "tab_names",
    defaults = {
        enabled = true,
        cursorName = true,
        size = 20,
        position = "above",
        skipPlates = false,
        players = true,
        npcs = true,
        enemies = true,
        worldOnly = true,
        delay = 0,          -- tenths of a second before the name shows
        hideCombat = false,
        hideInstances = false,
        tooltipCursor = false,
        tooltipScale = 100,
    },
}
ns.RegisterModule(mod)

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

local function HasNameplate()
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, "mouseover")
    return ok and plate ~= nil
end

-- True if the character under the mouse should get the name at the cursor.
local function WantsHovered()
    local db = mod.db
    if not Yes(UnitExists("mouseover")) then return false end
    if Yes(UnitIsUnit("mouseover", "player")) then return false end
    if db.worldOnly and not MouseOverWorld() then return false end
    if db.hideCombat and (InCombatLockdown() or Yes(UnitAffectingCombat("player"))) then return false end
    if db.hideInstances then
        local inInstance, kind = IsInInstance()
        if inInstance and kind ~= "none" then return false end
    end
    if db.skipPlates and HasNameplate() then return false end
    if not db.enemies then
        local canAttack = UnitCanAttack("player", "mouseover")
        if not ns.IsSecret(canAttack) and canAttack then return false end
    end
    local isPlayer = UnitIsPlayer("mouseover")
    if ns.IsSecret(isPlayer) then return db.players or db.npcs end
    if isPlayer then return db.players end
    return db.npcs
end

---------------------------------------------------------------------------
-- Name at the cursor
---------------------------------------------------------------------------
local label = CreateFrame("Frame", nil, UIParent)
label:SetFrameStrata("TOOLTIP")
label:SetSize(1, 1)
label:SetAlpha(0)
label:Hide()
local text = label:CreateFontString(nil, "OVERLAY")

local OFFSETS = {
    above = { "BOTTOM", 0, 24 },
    right = { "LEFT", 28, 0 },
    below = { "TOP", 0, -32 },
}

local function PlaceText()
    local o = OFFSETS[mod.db.position] or OFFSETS.above
    text:ClearAllPoints()
    text:SetPoint(o[1], label, "CENTER", o[2], o[3])
end

local function ApplyFont()
    local font = UNIT_NAME_FONT or STANDARD_TEXT_FONT
    if not text:SetFont(font, mod.db.size, "OUTLINE") then
        text:SetFont(STANDARD_TEXT_FONT, mod.db.size, "OUTLINE")
    end
    text:SetShadowOffset(1, -1)
    text:SetShadowColor(0, 0, 0, 1)
    PlaceText()
end

-- Follows the cursor every frame while the name is on screen.
label:SetScript("OnUpdate", function(self)
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end)

local showing = false
local hoverUntil = 0
local hoverStart -- when the mouse started hovering a character
local hoveredName = ""

-- Name and color the game uses for the hovered character.
local function SetFromMouseover()
    local name = UnitName("mouseover")
    if ns.IsSecret(name) then
        pcall(text.SetText, text, name) -- can't be read, but can be shown
        hoveredName = "?"
    else
        text:SetText(name or "")
        hoveredName = name or "?"
    end
    local ok, r, g, b = pcall(UnitSelectionColor, "mouseover")
    if not ok or ns.IsSecret(r) or ns.IsSecret(g) or ns.IsSecret(b) or not r then
        r, g, b = 1, 0.82, 0
    end
    -- Friendly players come back as pure blue, but the game draws their
    -- names in a lighter blue (measured in game: 102, 102, 255).
    if r < 0.05 and g < 0.05 and b > 0.95 then
        r, g, b = 0.4, 0.4, 1
    end
    text:SetTextColor(r, g, b)
end

local lastGUID
local UpdateTooltipDelay -- defined in the tooltip section

function mod.OnTick(now)
    UpdateTooltipDelay(now)
    local db = mod.db
    local want = db.enabled and db.cursorName and WantsHovered()
    if want then
        hoverStart = hoverStart or now
        if not showing and now - hoverStart < db.delay / 10 then return end
        hoverUntil = now + LINGER
        local guid = UnitGUID("mouseover")
        if ns.IsSecret(guid) then guid = nil end
        if not showing or guid ~= lastGUID or guid == nil then
            SetFromMouseover()
            lastGUID = guid
        end
        if not showing then
            showing = true
            label:Show()
        end
    else
        hoverStart = nil
        if showing and now >= hoverUntil then
            showing = false
            lastGUID = nil
        end
    end

    -- Fade in and out with the addon's fade smoothness.
    if label:IsShown() then
        local busy = ns.Fade(label, showing and 1 or 0)
        if not showing and not busy then label:Hide() end
    end
end

---------------------------------------------------------------------------
-- Tooltip at the cursor
---------------------------------------------------------------------------
-- The game calls GameTooltip_SetDefaultAnchor for tooltips that would go to
-- the corner (world objects, characters and many buttons). Right after it,
-- the tooltip is moved next to the cursor and scaled.
--
-- Delay: when the tooltip opens while the mouse is over the world (a
-- character, NPC or object), it stays invisible for the same delay as the
-- name. Tooltips of buttons and windows are never delayed. The tooltip is
-- kept invisible every frame, because the game sets its opacity itself.
local tooltipHooked = false
local tooltipPendingUntil -- time the delayed tooltip becomes visible

local function DelayTooltip(tooltip)
    local db = mod.db
    if not (db and db.enabled) or db.delay <= 0 then return end
    if not MouseOverWorld() then return end
    tooltipPendingUntil = GetTime() + db.delay / 10
    tooltip:SetAlpha(0)
end

-- Called every frame while the tooltip is shown.
local function HoldTooltip(tooltip)
    if not tooltipPendingUntil then return end
    if GetTime() >= tooltipPendingUntil then
        tooltipPendingUntil = nil
        tooltip:SetAlpha(1)
    elseif tooltip:GetAlpha() > 0 then
        tooltip:SetAlpha(0)
    end
end

-- Called every tick, in case the tooltip hid without its OnHide running.
function UpdateTooltipDelay()
    if tooltipPendingUntil and not GameTooltip:IsShown() then
        tooltipPendingUntil = nil
    end
end

local function HookTooltip()
    if tooltipHooked or not GameTooltip_SetDefaultAnchor then return end
    tooltipHooked = true
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        if tooltip ~= GameTooltip then return end
        local db = mod.db
        if not (db and db.enabled) then return end
        if db.tooltipCursor then
            pcall(tooltip.SetOwner, tooltip, parent, "ANCHOR_CURSOR_RIGHT", 24, 8)
        end
        if db.tooltipScale ~= 100 then
            tooltip:SetScale(db.tooltipScale / 100)
        end
    end)
    GameTooltip:HookScript("OnShow", DelayTooltip)
    GameTooltip:HookScript("OnUpdate", HoldTooltip)
    -- Other tooltips (items, spells) keep their normal size.
    GameTooltip:HookScript("OnHide", function(self)
        if self:GetScale() ~= 1 then self:SetScale(1) end
        if tooltipPendingUntil then
            tooltipPendingUntil = nil
            self:SetAlpha(1)
        end
    end)
end

---------------------------------------------------------------------------
-- Module hooks
---------------------------------------------------------------------------
function mod.SetEnabled(v)
    mod.db.enabled = v
end

function mod.OnLogin()
    ApplyFont()
    HookTooltip()
    -- Earlier versions could leave the minimum name size raised.
    if mod.db.savedSize ~= nil then
        pcall(SetCVar, "WorldTextMinSize", tostring(mod.db.savedSize))
        mod.db.savedSize = nil
    end
    mod.db.fallbackAll, mod.db.fallbackSize = nil, nil
end

function mod.BuildOptions(parent, y)
    local refreshers = {}
    local function add(r) refreshers[#refreshers + 1] = r end
    local function set(key) return function(v) mod.db[key] = v end end

    add(ns.CreateCheck(parent, L.enabled, y,
        function() return mod.db.enabled end, function(v) mod.SetEnabled(v) end))
    y = y - 36

    add(ns.CreateCheck(parent, L.nm_cursorName, y,
        function() return mod.db.cursorName end, set("cursorName")))
    y = y - 34
    add(ns.CreateSlider(parent, L.nm_size, y,
        function() return mod.db.size end,
        function(v) mod.db.size = v; ApplyFont() end, 10, 40,
        function(v) return tostring(math.floor(v + 0.5)) end))
    y = y - 32
    add(ns.CreateDropdown(parent, L.nm_position, y, POSITIONS,
        function() return mod.db.position end,
        function(v) mod.db.position = v; PlaceText() end))
    y = y - 32
    add(ns.CreateStepper(parent, L.nm_delay, y,
        function() return mod.db.delay end, set("delay"), 0, 10, 1,
        function(v) return string.format("%.1f s", v / 10) end))
    y = y - 30
    add(ns.CreateCheck(parent, L.nm_skipPlates, y,
        function() return mod.db.skipPlates end, set("skipPlates")))
    y = y - 34

    ns.CreateHeader(parent, L.nm_who, y)
    y = y - 22
    for _, item in ipairs({ { "nm_players", "players" }, { "nm_npcs", "npcs" }, { "nm_enemies", "enemies" } }) do
        add(ns.CreateCheck(parent, L[item[1]], y,
            function() return mod.db[item[2]] end, set(item[2])))
        y = y - 28
    end
    add(ns.CreateCheck(parent, L.nm_worldOnly, y,
        function() return mod.db.worldOnly end, set("worldOnly")))
    y = y - 28
    add(ns.CreateCheck(parent, L.nm_hideCombat, y,
        function() return mod.db.hideCombat end, set("hideCombat")))
    y = y - 28
    add(ns.CreateCheck(parent, L.nm_hideInstances, y,
        function() return mod.db.hideInstances end, set("hideInstances")))
    y = y - 38

    ns.CreateHeader(parent, L.nm_tooltipHeader, y)
    y = y - 22
    add(ns.CreateCheck(parent, L.nm_tooltipCursor, y,
        function() return mod.db.tooltipCursor end, set("tooltipCursor")))
    y = y - 32
    add(ns.CreateSlider(parent, L.nm_tooltipScale, y,
        function() return mod.db.tooltipScale end, set("tooltipScale"), 50, 200,
        function(v) return math.floor(v + 0.5) .. "%" end))
    y = y - 40
    ns.CreateNote(parent, L.nm_note, y)

    return function() for _, r in ipairs(refreshers) do r() end end
end

function mod.PrintStatus()
    local state
    if not mod.db.enabled then
        state = L.nm_st_disabled
    elseif showing then
        state = string.format(L.nm_st_showing, hoveredName)
    else
        state = L.nm_st_idle
    end
    ns.Print(L.nm_title .. ": " .. state)
end