-- UI Visibility: element engine
-- Shared by the modules that control groups of interface elements. Each
-- element has three modes:
--   shown:  normal game behavior. The addon brings the element back to normal
--           once and then leaves it alone, so the game's own fades (like the
--           chat tabs) keep working.
--   hidden: invisible, and every part of it that uses the mouse ignores it.
--   hover:  invisible until the cursor is over any part of it.
-- Everything is shown in Edit Mode.
--
-- Performance:
--   * Each element's frames are found once and kept. They are looked up
--     again on the slow tick (every 5 seconds). Expensive searches (addon
--     buttons) only run when asked to.
--   * The fast tick only works while something can change: an element in
--     On hover mode, an element that can force itself visible, a fade in
--     progress, or right after a change. If the game changes the opacity of
--     a controlled element, that counts as a change.

local ADDON_NAME, ns = ...
local L = ns.Lproxy
local MODES = { "shown", "hidden", "hover" }
local LINGER = 0.5 -- seconds an element stays visible after the mouse leaves

ns.AddLocale("en", {
    linkHover = "Show hover elements together",
    linkHover_tip = "Hovering any element in On hover mode shows all of them at once.",
    minimapHover_tip = "Hovering the minimap shows every element in On hover mode.",
    sec_options = "Options",
    sec_elements = "Elements",
    modesNote = "Shown: the game's normal behavior. Hidden: invisible, and it ignores the mouse. On hover: invisible until the mouse passes over it.",
    modesHeader = "Elements",
    st_notShown = "not shown right now",
    st_edit = "Edit Mode",
    st_hoverOn = "mouse over it", st_hoverOff = "waiting for the mouse",
    st_pending = " (mouse change pending until combat ends)",
    st_found = "%d found",
})
ns.AddLocale("es", {
    linkHover = "Mostrar juntos al apuntar",
    linkHover_tip = "Apuntar a cualquier elemento en modo Con el mouse muestra todos a la vez.",
    minimapHover_tip = "Apuntar al minimapa muestra todos los elementos en modo Con el mouse.",
    sec_options = "Opciones",
    sec_elements = "Elementos",
    modesNote = "Visible: el comportamiento normal del juego. Oculto: invisible, y no responde al mouse. Con el mouse: invisible hasta que el mouse pasa por encima.",
    modesHeader = "Elementos",
    st_notShown = "no se muestra ahora",
    st_edit = "Modo Edición",
    st_hoverOn = "mouse encima", st_hoverOff = "esperando el mouse",
    st_pending = " (cambio de mouse pendiente hasta salir de combate)",
    st_found = "%d encontrados",
})

-- Helper for finders: adds a frame to a list if it can be used.
function ns.AddFrame(list, frame)
    if type(frame) ~= "table" or not frame.GetAlpha then return end
    if frame.IsForbidden and frame:IsForbidden() then return end
    list[#list + 1] = frame
end

-- cfg fields:
--   key, titleKey, tabKey: module identity and labels.
--   elements: list of
--     { key, label, frame = "path" }  or  { key, label, find = function(mod) }
--     optional: multi = true (shown as a count in status),
--               expensive = true (find only runs on full refreshes),
--               forceShow = function() returning true to show it anyway.
--   defaults: module settings (enabled, linkHover, modes, ...).
--   minimapHover, minimapHoverLabel: offer "show when hovering the minimap".
--   noteKey: text shown under the mode buttons.
function ns.NewElementsModule(cfg)
    local mod = {
        key = cfg.key, titleKey = cfg.titleKey, tabKey = cfg.tabKey,
        defaults = cfg.defaults,
    }

    local frameLists = {}   -- element key -> list of frames
    local managed = {}      -- frame -> element key
    local released = {}     -- frame -> true when the game has it back
    local mouseState = {}   -- frame -> last mouse state applied
    local disabledParts = {}
    local hooked = {}
    local dirty = true
    local applying = false
    local hoverUntil = {}   -- element key -> time it stops counting as hovered
    local groupUntil, minimapUntil = 0, 0
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
            -- A part whose answer is secret is left as it is.
            local enabled = f:IsMouseEnabled()
            if not ns.IsSecret(enabled) and enabled then
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

    -- If the game changes a frame's opacity, check it again on the next tick.
    local function Hook(frame)
        if hooked[frame] then return end
        hooked[frame] = true
        pcall(hooksecurefunc, frame, "SetAlpha", function()
            if not applying and not released[frame] then dirty = true end
        end)
    end

    local function ElementReleased(elementKey)
        local db = mod.db
        return not db.enabled or ns.IsEditMode() or db.modes[elementKey] == "shown"
    end

    -- Rebuilds the frame lists. "full" also runs the expensive finders.
    function mod.RefreshLists(full)
        for _, element in ipairs(cfg.elements) do
            if element.find then
                if full or not element.expensive or not frameLists[element.key] then
                    frameLists[element.key] = element.find(mod)
                end
            else
                local list = {}
                ns.AddFrame(list, ns.Resolve(element.frame))
                frameLists[element.key] = list
            end
        end

        local current = {}
        for _, element in ipairs(cfg.elements) do
            for _, frame in ipairs(GetFrames(element)) do
                current[frame] = element.key
            end
        end
        -- Frames that left every list get their normal look back.
        for frame in pairs(managed) do
            if not current[frame] and not IsLocked(frame) then
                if not released[frame] then frame:SetAlpha(1) end
                RestoreMouse(frame)
                mouseState[frame] = nil
                released[frame] = nil
                managed[frame] = nil
            end
        end
        -- New frames in Shown mode start released: the addon doesn't touch them.
        for frame, elementKey in pairs(current) do
            if not managed[frame] then
                managed[frame] = elementKey
                Hook(frame)
                if ElementReleased(elementKey) then released[frame] = true end
            end
        end
        dirty = true
    end

    local function UpdateHover(now)
        local db = mod.db
        if cfg.minimapHover and db.minimapHover and Minimap and ns.IsCursorOver(Minimap) then
            minimapUntil = now + LINGER
        end
        local any = false
        for _, element in ipairs(cfg.elements) do
            if db.modes[element.key] == "hover" then
                for _, frame in ipairs(GetFrames(element)) do
                    if ns.IsCursorOver(frame) then
                        hoverUntil[element.key] = now + LINGER
                        any = true
                        break
                    end
                end
            end
        end
        if any then groupUntil = now + LINGER end
    end

    -- Returns opacity, mouse, and whether the element goes back to the game.
    local function Targets(element, now)
        local db = mod.db
        if ElementReleased(element.key) then return 1, true, true end
        if element.forceShow and element.forceShow() then return 1, true, false end
        local mode = db.modes[element.key]
        if mode == "hidden" then return 0, false, false end
        -- hover
        if now < (hoverUntil[element.key] or 0) then return 1, true, false end
        if db.linkHover and now < groupUntil then return 1, true, false end
        if cfg.minimapHover and db.minimapHover and now < minimapUntil then return 1, true, false end
        return 0, true, false
    end

    -- Applies the targets to one frame. Returns true if work remains.
    local function UpdateFrame(frame, alpha, mouse, release)
        if release and released[frame] then return false end
        if not release then released[frame] = nil end

        applying = true
        local busy = ns.Fade(frame, alpha)
        applying = false

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

        if release and not busy then released[frame] = true end
        return busy
    end

    -- True while the module has to check things on every tick.
    local function NeedsPolling()
        local db = mod.db
        if not db.enabled then return false end
        if cfg.minimapHover and db.minimapHover then return true end
        for _, element in ipairs(cfg.elements) do
            local mode = db.modes[element.key]
            if mode == "hover" then return true end
            if element.forceShow and mode ~= "shown" then return true end
        end
        return false
    end

    function mod.OnTick(now)
        if not mod.db then return end
        local poll = NeedsPolling()
        if not dirty and not poll then return end
        if poll then UpdateHover(now) end
        local busy = false
        for _, element in ipairs(cfg.elements) do
            local alpha, mouse, release = Targets(element, now)
            for _, frame in ipairs(GetFrames(element)) do
                if UpdateFrame(frame, alpha, mouse, release) then busy = true end
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

    function mod.SetEnabled(v)
        mod.db.enabled = v
        dirty = true
    end

    function mod.BuildOptions(parent, y)
        local refreshers = {}
        local function add(r) refreshers[#refreshers + 1] = r end

        add(ns.CreateCheck(parent, L.enabled, y,
            function() return mod.db.enabled end, function(v) mod.SetEnabled(v) end))
        y = y - 40

        ns.CreateSection(parent, L.sec_options, y)
        y = y - 32
        add(ns.CreateCheck(parent, L.linkHover, y,
            function() return mod.db.linkHover end, function(v) mod.db.linkHover = v; dirty = true end,
            { tooltip = L.linkHover_tip }))
        y = y - 28
        if cfg.minimapHover then
            add(ns.CreateCheck(parent, L[cfg.minimapHoverLabel], y,
                function() return mod.db.minimapHover end, function(v) mod.db.minimapHover = v; dirty = true end,
                { tooltip = L.minimapHover_tip }))
            y = y - 28
        end
        y = y - 12

        ns.CreateSection(parent, L.sec_elements, y)
        y = y - 30
        y = y - ns.CreateNote(parent, L.modesNote, y) - 16
        for _, element in ipairs(cfg.elements) do
            add(ns.CreateDropdown(parent, L[element.label], y, MODES,
                function() return mod.db.modes[element.key] end,
                function(v) mod.db.modes[element.key] = v; dirty = true end))
            y = y - 32
        end
        if cfg.noteKey then ns.CreateNote(parent, L[cfg.noteKey], y - 4) end

        return function() for _, r in ipairs(refreshers) do r() end end
    end

    function mod.PrintStatus()
        local now = GetTime()
        for _, element in ipairs(cfg.elements) do
            local frames = GetFrames(element)
            local frame = frames[1]
            local mode = L[mod.db.modes[element.key]]
            local detail
            if not frame then
                detail = mode .. ", " .. L.notFound
            elseif element.multi then
                detail = mode .. ", " .. string.format(L.st_found, #frames)
            elseif not ns.IsSecret(frame:IsShown()) and not frame:IsShown() then
                detail = mode .. ", " .. L.st_notShown
            elseif ns.IsEditMode() then
                detail = L.st_edit
            else
                detail = mode
                if mod.db.modes[element.key] == "hover" then
                    detail = detail .. ", " .. (ns.IsCursorOver(frame) and L.st_hoverOn or L.st_hoverOff)
                end
                local _, mouse = Targets(element, now)
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