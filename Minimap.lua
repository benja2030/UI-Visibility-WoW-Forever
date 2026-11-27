-- UI Visibility: minimap module
-- Elements around the minimap, using the element engine, plus the minimap
-- buttons that other addons add.
--
-- Performance: the addon button search goes through every child of UIParent,
-- so it runs only after login, a few times while addons finish loading,
-- when an addon loads later, once a minute, and with /uiv list.

local ADDON_NAME, ns = ...
local L = ns.Lproxy

ns.AddLocale("en", {
    tab_minimap = "Minimap",
    mm_title = "Minimap elements",
    mm_minimapHover = "Show them over the minimap",
    mm_zone = "Zone text", mm_clock = "Clock", mm_calendar = "Calendar", mm_tracking = "Tracking",
    mm_mail = "Mail and indicators", mm_addons = "Addon button", mm_border = "Compass border",
    mm_daynight = "Day/night icon", mm_buttons = "Addon minimap buttons",
    mm_note = "Missing an addon button? Find its name with /fstack, then /uiv add Name.",
    mm_addUsage = "usage: /uiv add FrameName (use /fstack to see the name)",
    mm_added = "added %s to the addon minimap buttons.",
    mm_removed = "removed %s from the list.",
    mm_notInList = "%s isn't in the list.",
    mm_noFrame = "there's no frame called %s right now. Check the name with /fstack (it's case-sensitive).",
    mm_listHeader = "addon minimap buttons found:",
    mm_listEmpty = "no addon minimap buttons found.",
    mm_manual = " (added by you)",
})
ns.AddLocale("es", {
    tab_minimap = "Minimapa",
    mm_title = "Elementos del minimapa",
    mm_minimapHover = "Mostrarlos al apuntar al minimapa",
    mm_zone = "Texto de zona", mm_clock = "Reloj", mm_calendar = "Calendario", mm_tracking = "Rastreo",
    mm_mail = "Correo e indicadores", mm_addons = "Botón de addons", mm_border = "Borde de brújula",
    mm_daynight = "Ícono de día/noche", mm_buttons = "Botones de addons",
    mm_note = "¿Falta un botón de addon? Busca su nombre con /fstack y usa /uiv add Nombre.",
    mm_addUsage = "uso: /uiv add NombreDelMarco (usa /fstack para ver el nombre)",
    mm_added = "agregué %s a los botones de addons.",
    mm_removed = "quité %s de la lista.",
    mm_notInList = "%s no está en la lista.",
    mm_noFrame = "no existe un marco llamado %s ahora. Revisa el nombre con /fstack (distingue mayúsculas y minúsculas).",
    mm_listHeader = "botones de addons encontrados:",
    mm_listEmpty = "no encontré botones de addons.",
    mm_manual = " (agregado por ti)",
})

-- Day/night icon: it has no name, and other addons can move it, so it's
-- recognized by what it is: a small child of the minimap container, other
-- than the minimap itself, with its own background (.Background).
local function FindDayNight()
    local container = MinimapCluster and MinimapCluster.MinimapContainer
    if not container then return {} end
    for _, child in ipairs({ container:GetChildren() }) do
        if child ~= Minimap and child.Background and not (child.IsForbidden and child:IsForbidden()) then
            local width = child:GetWidth()
            if not ns.IsSecret(width) and width > 0 and width < 80 then
                return { child }
            end
        end
    end
    return {}
end

-- Addon minimap buttons, from three sources:
--   1. LibDBIcon, the library most addons use for their minimap button.
--   2. Children of the minimap, the minimap cluster and UIParent whose name
--      contains "MinimapButton", or named buttons on UIParent anchored to
--      the minimap.
--   3. Names the user added with /uiv add.
local function FindAddonButtons(mod)
    local found, seen = {}, {}
    local function add(f)
        if type(f) ~= "table" or not f.GetAlpha then return end
        if f.IsForbidden and f:IsForbidden() then return end
        if not seen[f] then
            seen[f] = true
            found[#found + 1] = f
        end
    end

    local lib = LibStub and LibStub("LibDBIcon-1.0", true)
    if lib and lib.objects then
        for _, button in pairs(lib.objects) do add(button) end
    end

    -- Some frames are forbidden (Blizzard blocks addons from even reading
    -- them), so they are skipped, and each check runs protected.
    local function check(parent, child)
        if child.IsForbidden and child:IsForbidden() then return end
        local name = child:GetName()
        if not name then return end
        if name:lower():find("minimapbutton", 1, true) then
            add(child)
        elseif parent == UIParent and child:GetObjectType() == "Button" then
            local _, relativeTo = child:GetPoint(1)
            if relativeTo == Minimap then add(child) end
        end
    end

    for _, parent in ipairs({ Minimap, MinimapCluster, UIParent }) do
        if parent then
            for _, child in ipairs({ parent:GetChildren() }) do
                pcall(check, parent, child)
            end
        end
    end

    for name in pairs(mod.db.extraButtons) do add(_G[name]) end
    return found
end

local mod = ns.NewElementsModule({
    key = "minimap", titleKey = "mm_title", tabKey = "tab_minimap",
    minimapHover = true, minimapHoverLabel = "mm_minimapHover",
    noteKey = "mm_note", showNote = true,
    elements = {
        { key = "zone",     label = "mm_zone",     frame = "MinimapCluster.ZoneTextButton" },
        { key = "clock",    label = "mm_clock",    frame = "TimeManagerClockButton" },
        { key = "calendar", label = "mm_calendar", frame = "GameTimeFrame" },
        { key = "tracking", label = "mm_tracking", frame = "MinimapCluster.Tracking" },
        { key = "mail",     label = "mm_mail",     frame = "MinimapCluster.IndicatorFrame" },
        { key = "addons",   label = "mm_addons",   frame = "AddonCompartmentFrame" },
        { key = "border",   label = "mm_border",   frame = "MinimapCompassTexture" },
        { key = "daynight", label = "mm_daynight", find = FindDayNight },
        { key = "buttons",  label = "mm_buttons",  find = FindAddonButtons, expensive = true, multi = true },
    },
    defaults = {
        enabled = true,
        linkHover = true,
        minimapHover = false,
        extraButtons = {},
        modes = {
            zone = "shown", clock = "shown", calendar = "shown", tracking = "shown",
            mail = "shown", addons = "shown", border = "shown",
            daynight = "shown", buttons = "shown",
        },
    },
})

-- Full searches: after login (addons often create buttons a bit late),
-- when another addon loads, and once a minute.
local scanPending = false
local function ScheduleFullScan(delay)
    if scanPending then return end
    scanPending = true
    C_Timer.After(delay, function()
        scanPending = false
        mod.RefreshLists(true)
    end)
end

local engineLogin = mod.OnLogin
function mod.OnLogin()
    engineLogin()
    C_Timer.After(3, function() mod.RefreshLists(true) end)
    C_Timer.After(10, function() mod.RefreshLists(true) end)
    C_Timer.After(30, function() mod.RefreshLists(true) end)
end

local slowCount = 0
local engineSlowTick = mod.OnSlowTick
function mod.OnSlowTick()
    slowCount = slowCount + 1
    if slowCount >= 12 then -- 12 x 5 seconds = once a minute
        slowCount = 0
        mod.RefreshLists(true)
    else
        engineSlowTick()
    end
end

function mod.OnAddonLoaded()
    if mod.db then ScheduleFullScan(2) end
end

-- Commands: list, add, remove.
local BUTTONS_ELEMENT = { key = "buttons" }

function mod.Command(cmd, arg)
    if cmd == "list" or cmd == "lista" then
        mod.RefreshLists(true)
        local frames = mod.GetFrames(BUTTONS_ELEMENT)
        if #frames == 0 then ns.Print(L.mm_listEmpty); return true end
        ns.Print(L.mm_listHeader)
        for _, f in ipairs(frames) do
            local name = f:GetName() or "?"
            print("   " .. name .. (mod.db.extraButtons[name] and L.mm_manual or ""))
        end
        return true
    elseif cmd == "add" then
        if arg == "" then ns.Print(L.mm_addUsage); return true end
        if not _G[arg] then ns.Print(string.format(L.mm_noFrame, arg)); return true end
        mod.db.extraButtons[arg] = true
        mod.RefreshLists(true)
        ns.Print(string.format(L.mm_added, arg))
        return true
    elseif cmd == "remove" then
        if arg == "" then ns.Print(L.mm_addUsage); return true end
        if not mod.db.extraButtons[arg] then ns.Print(string.format(L.mm_notInList, arg)); return true end
        mod.db.extraButtons[arg] = nil
        mod.RefreshLists(true)
        ns.Print(string.format(L.mm_removed, arg))
        return true
    end
    return false
end