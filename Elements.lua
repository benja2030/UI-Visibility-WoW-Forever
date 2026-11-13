-- UI Visibility: element engine
-- Shared by the Class Bars and Minimap modules. Each element has three modes:
--   shown:  normal game behavior.
--   hidden: invisible, and every part of it that uses the mouse ignores it.
--   hover:  invisible until the cursor is over it.
-- Everything is shown in Edit Mode.
--
-- Performance:
--   * Each element's frames are found once and kept. They are looked up
--     again on the slow tick (every 5 seconds) in case the game recreated
--     them. Expensive searches (addon buttons) only run when asked to.
--   * The fast tick only does work while something can change: an element
--     in On hover mode, a fade in progress, or right after a change.

local ADDON_NAME, ns = ...
local L = ns.Lproxy
local MODES = { "shown", "hidden", "hover" }
local LINGER = 0.5 -- seconds a hover group stays visible after the mouse leaves

ns.AddLocale("en", {
    linkHover = "Show all On hover elements together",
    modesHeader = "Click a button to change the mode:",
    st_notShown = "not shown right now",
    st_edit = "Edit Mode",
    st_hoverOn = "mouse over it", st_hoverOff = "waiting for the mouse",
    st_pending = " (mouse change pending until combat ends)",
    st_found = "%d found",
})
ns.AddLocale("es", {
    linkHover = "Mostrar juntos los elementos Con el mouse",
    modesHeader = "Haz clic en un botón para cambiar el modo:",
    st_notShown = "no se muestra ahora",
    st_edit = "Modo Edición",
    st_hoverOn = "mouse encima", st_hoverOff = "esperando el mouse",
    st_pending = " (cambio de mouse pendiente hasta salir de combate)",
    st_found = "%d encontrados",
})

-- cfg fields:
--   key, titleKey, tabKey: module identity and labels.
--   elements: list of { key, label, frame = "path" } or { key, label, find = function }.
--     An element with "multi = true" can have several frames (shown as a count).
--   defaults: module settings (must include enabled, linkHover, modes).
--   minimapHover: offer "show when hovering the minimap".
--   minimapHoverLabel: text for that option.
--   noteKey: text shown under the mode buttons.
--   extraOptions(parent, y, mod): optional, adds widgets; returns refresh, newY.
function ns.NewElementsModule(cfg)
    local mod = {
        key = cfg.key, titleKey = cfg.titleKey, tabKey = cfg.tabKey,
        defaults = cfg.defaults,
    }

    local frameLists = {}   -- element key -> list of frames
    local managed = {}      -- frames this module controls
    local mouseState = {}   -- frame -> last mouse state applied
    local disabledParts = {}
    local dirty = true
    local lastGroupHover, lastMinimapHover = 0, 0
    local EMPTY = {}

    function mod.MarkDirty() dirty = true end

    local function GetFrames(element) return frameLists[element.key] or EMPTY end
    mod.GetFrames = GetFrames

    -- Mouse: turns it off for every part of a frame that uses it, remembering
    -- which ones, so exactly those can be turned back on later.
    local function DisableMouse(frame)
        disabledParts[frame] = disabledParts[frame] or {}
        local list = disabledParts[frame]
        local function walk(f)
            if not f.GetChildren then return end
            if f:IsMouseEnabled() then
                f:EnableMouse(false)
                list[#list + 1] = f
            end
            for _, child in ipairs({ f:GetChildren() }) do walk(child) end
        end
        walk(frame)
    end

    local function RestoreMouse(frame)
        local list = disabledParts[frame]
        if not list then return end
        for _, f in ipairs(list) do f:EnableMouse(true) end
        disabledParts[frame] = nil
    end

    local function IsLocked(frame)
        return InCombatLockdown() and frame.IsProtected and frame:IsProtected()
    end

    -- Rebuilds the frame lists. "full" also runs the expensive finders.
    function mod.RefreshLists(full)
        for _, element in ipairs(cfg.elements) do
            if element.find then
                if full or not element.expensive or not frameLists[element.key] then
                    frameLists[element.key] = element.find(mod)
                end
            else
                local frame = ns.Resolve(element.frame)
                frameLists[element.key] = frame and { frame } or {}
            end
        end
        -- Frames that left every list get their normal look back.
        local current = {}
        for _, list in pairs(frameLists) do
            for _, frame in ipairs(list) do current[frame] = true end
        end
        for frame in pairs(managed) do
            if not current[frame] and not IsLocked(frame) then
                frame:SetAlpha(1)
                RestoreMouse(frame)
                mouseState[frame] = nil
                managed[frame] = nil
            end
        end
        for frame in pairs(current) do managed[frame] = true end
        dirty = true
    end

    local function UpdateGroupHover()
        local db = mod.db
        if cfg.minimapHover and db.minimapHover and Minimap and ns.IsCursorOver(Minimap) then
            lastMinimapHover = GetTime()
            lastGroupHover = GetTime()
            return
        end
        if not db.linkHover then return end
        for _, element in ipairs(cfg.elements) do
            if db.modes[element.key] == "hover" then
                for _, frame in ipairs(GetFrames(element)) do
                    if ns.IsCursorOver(frame) then
                        lastGroupHover = GetTime(); return
                    end
                end
            end
        end
    end

    -- Target opacity and whether the frame should take the mouse.
    local function Targets(element, frame)
        local db = mod.db
        if not db.enabled or ns.IsEditMode() then return 1, true end
        local mode = db.modes[element.key]
        if mode == "hidden" then return 0, false end
        if mode == "hover" then
            local now = GetTime()
            if db.linkHover then return (now - lastGroupHover < LINGER) and 1 or 0, true end
            if cfg.minimapHover and db.minimapHover and now - lastMinimapHover < LINGER then
                return 1, true
            end
            return ns.IsCursorOver(frame) and 1 or 0, true
        end
        return 1, true
    end
    mod.Targets = Targets

    -- Applies the targets to one frame. Returns true if work remains.
    local function UpdateFrame(element, frame)
        local alpha, mouse = Targets(element, frame)
        local busy = ns.Fade(frame, alpha)
        local last = mouseState[frame]
        if last == nil then last = true end
        if last ~= mouse then
            if IsLocked(frame) then
                busy = true
            else
                if mouse then RestoreMouse(frame) else DisableMouse(frame) end
                mouseState[frame] = mouse
            end
        end
        return busy
    end

    local function AnyHover()
        local db = mod.db
        if not db.enabled then return false end
        if cfg.minimapHover and db.minimapHover then return true end
        for _, element in ipairs(cfg.elements) do
            if db.modes[element.key] == "hover" then return true end
        end
        return false
    end

    function mod.OnTick()
        if not mod.db then return end
        local hover = AnyHover()
        if not dirty and not hover then return end
        if hover then UpdateGroupHover() end
        local busy = false
        for _, element in ipairs(cfg.elements) do
            for _, frame in ipairs(GetFrames(element)) do
                if UpdateFrame(element, frame) then busy = true end
            end
        end
        dirty = busy
    end

    function mod.OnSlowTick()
        mod.RefreshLists(false)
    end

    function mod.OnLogin()
        mod.RefreshLists(true)
    end

    -- When disabled, Targets returns "shown" for everything, so the next
    -- ticks restore the normal look and then go idle.
    function mod.SetEnabled(v)
        mod.db.enabled = v
        dirty = true
    end

    function mod.BuildOptions(parent, y)
        local refreshers = {}
        local function add(r) refreshers[#refreshers + 1] = r end

        add(ns.CreateCheck(parent, L.enabled, y,
            function() return mod.db.enabled end, function(v) mod.SetEnabled(v) end))
        y = y - 28
        add(ns.CreateCheck(parent, L.linkHover, y,
            function() return mod.db.linkHover end, function(v) mod.db.linkHover = v; dirty = true end))
        y = y - 28
        if cfg.minimapHover then
            add(ns.CreateCheck(parent, L[cfg.minimapHoverLabel], y,
                function() return mod.db.minimapHover end, function(v) mod.db.minimapHover = v; dirty = true end))
            y = y - 28
        end
        y = y - 8

        ns.CreateHeader(parent, L.modesHeader, y)
        y = y - 26
        for _, element in ipairs(cfg.elements) do
            add(ns.CreateCycle(parent, L[element.label], y, MODES,
                function() return mod.db.modes[element.key] end,
                function(v) mod.db.modes[element.key] = v; dirty = true end))
            y = y - 30
        end
        if cfg.noteKey then ns.CreateNote(parent, L[cfg.noteKey], y - 2) end

        return function() for _, r in ipairs(refreshers) do r() end end
    end

    function mod.PrintStatus()
        for _, element in ipairs(cfg.elements) do
            local frames = GetFrames(element)
            local frame = frames[1]
            local mode = L[mod.db.modes[element.key]]
            local detail
            if not frame then
                detail = mode .. ", " .. L.notFound
            elseif element.multi then
                detail = mode .. ", " .. string.format(L.st_found, #frames)
            elseif not frame:IsShown() then
                detail = mode .. ", " .. L.st_notShown
            elseif ns.IsEditMode() then
                detail = L.st_edit
            else
                detail = mode
                if mod.db.modes[element.key] == "hover" then
                    detail = detail .. ", " .. (ns.IsCursorOver(frame) and L.st_hoverOn or L.st_hoverOff)
                end
                local _, mouse = Targets(element, frame)
                local last = mouseState[frame]
                if last == nil then last = true end
                if mouse ~= last then detail = detail .. L.st_pending end
            end
            ns.Print(L[element.label] .. ": " .. detail)
        end
    end

    ns.RegisterModule(mod)
    return mod
end
