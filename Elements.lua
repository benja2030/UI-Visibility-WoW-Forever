-- UI Visibility: element engine
-- Shared by the modules that control groups of interface elements. Each
-- element has three modes:
--   shown:  normal game behavior. The addon brings the element back to normal
--           once and then leaves it alone, so the game's own fades (like the
--           chat tabs) keep working.
--   hidden: invisible, and every part of it that uses the mouse ignores it.
--   custom: "Show when". The element is shown while any of its chosen
--           conditions is true (mouse over it, in combat, mounted...), at its
--           "shown" opacity, and kept at its "otherwise" opacity the rest of
--           the time (0% by default). While it's invisible (0%) it
--           ignores the mouse, so it can't be clicked by mistake.
--
-- Clicks in combat: the game doesn't let addons turn the mouse of protected
-- frames (action bars, unit frames) on or off during combat. So right
-- before combat starts (PLAYER_REGEN_DISABLED, the last moment it's
-- allowed), each Show when element gets the mouse it will keep for the whole
-- fight:
--   * visible at that moment (or shown by being in combat): clickable.
--   * invisible: not clickable if "Invisible elements can't be clicked in
--     combat" is on (the default); with it off, clickable if any of its
--     conditions can show it during the fight.
-- Keybinds always work. When combat ends, the mouse follows the element
-- again.
-- The old "hover" mode is now custom with only "mouse over it"; saved
-- settings are moved over at login.
-- Everything is shown in Edit Mode.
--
-- Performance:
--   * Each element's frames are found once and kept. They are looked up
--     again on the slow tick (every 5 seconds). Expensive searches (addon
--     buttons) only run when asked to.
--   * The fast tick only works while something can change: an element in
--     Show when mode, an element that can force itself visible, a fade in
--     progress, or right after a change. If the game changes the opacity of
--     a controlled element, that counts as a change.
--   * Each condition is asked to the game at most once per tick, however
--     many elements use it.

local ADDON_NAME, ns = ...
local L = ns.Lproxy
local LINGER = 0.5 -- seconds an element stays visible after the mouse leaves

-- Opacity choices, in percent.
local ALPHA_ON_VALUES = { 100, 90, 80, 70, 60, 50 }
local ALPHA_OFF_VALUES = { 0, 10, 20, 30, 40, 50, 60, 70, 80 }

ns.AddLocale("en", {
    linkHover = "Show hover elements together",
    linkHover_tip = "Hovering any element that shows with \"Mouse over it\" shows all of them at once.",
    minimapHover_tip = "Hovering the minimap shows every element that shows with \"Mouse over it\".",
    sec_options = "Options",
    sec_elements = "Elements",
    modesNote = "Hidden: invisible and not clickable. Show when: shows while any ticked condition is true, at the opacity you choose.",
    modesHeader = "Elements",
    custom = "Show when",
    showWhen = "Show when (any of these)",
    alphaOnMenu = "Opacity when shown: %d%%",
    alphaOffMenu = "Opacity otherwise: %d%%",
    cond_none = "No condition",
    cond_off = "None",
    cond_more = "%s +%d",
    cond_hover = "Mouse over it",       cond_hover_s = "On hover",
    cond_combat = "In combat",          cond_combat_s = "In combat",
    cond_nocombat = "Out of combat",    cond_nocombat_s = "Out of combat",
    cond_target = "I have a target",    cond_target_s = "Target",
    cond_enemy = "My target is an enemy", cond_enemy_s = "Enemy target",
    cond_group = "In a group",          cond_group_s = "Group",
    cond_instance = "In an instance",   cond_instance_s = "Instance",
    cond_resting = "Resting (inn or city)", cond_resting_s = "Resting",
    cond_mounted = "Mounted",           cond_mounted_s = "Mounted",
    cond_flying = "Flying",             cond_flying_s = "Flying",
    cond_swimming = "Swimming",         cond_swimming_s = "Swimming",
    cond_moving = "Moving",             cond_moving_s = "Moving",
    cond_still = "Standing still",      cond_still_s = "Still",
    cond_cursor = "Dragging a spell or item", cond_cursor_s = "Dragging",
    st_notShown = "not shown right now",
    st_edit = "Edit Mode",
    st_showing = "showing", st_waiting = "waiting",
    st_pending = " (mouse change pending until combat ends)",
    st_found = "%d found",
    blockClicks = "No clicks on invisible elements in combat",
    needsAddon = "%s (needs %s)",
    getAddon = "Needs the %s addon, available on CurseForge. Without it, this option is greyed out.",
    blockClicks_tip = "The game doesn't let addons change what can be clicked during combat, so it's decided when combat starts. "
        .. "On: an element that's invisible when combat starts can't be clicked until combat ends, even if it shows up (for example on hover). "
        .. "Off: it can be clicked during the whole fight, even while invisible. Keybinds always work. Out of combat, invisible elements are never clickable.",
})
ns.AddLocale("es", {
    linkHover = "Mostrar juntos al apuntar",
    linkHover_tip = "Apuntar a cualquier elemento que se muestra con \"Mouse encima\" muestra todos a la vez.",
    minimapHover_tip = "Apuntar al minimapa muestra todos los elementos que se muestran con \"Mouse encima\".",
    sec_options = "Opciones",
    sec_elements = "Elementos",
    modesNote = "Oculto: invisible y no se puede clickear. Mostrar cuando: se muestra mientras se cumpla una condición marcada, con la opacidad que elijas.",
    modesHeader = "Elementos",
    custom = "Mostrar cuando",
    showWhen = "Mostrar cuando (cualquiera)",
    alphaOnMenu = "Opacidad al mostrarse: %d%%",
    alphaOffMenu = "Opacidad el resto del tiempo: %d%%",
    cond_none = "Sin condición",
    cond_off = "Ninguna",
    cond_more = "%s +%d",
    cond_hover = "Mouse encima",        cond_hover_s = "Con el mouse",
    cond_combat = "En combate",         cond_combat_s = "En combate",
    cond_nocombat = "Fuera de combate", cond_nocombat_s = "Fuera de combate",
    cond_target = "Tengo un objetivo",  cond_target_s = "Objetivo",
    cond_enemy = "Mi objetivo es enemigo", cond_enemy_s = "Objetivo enemigo",
    cond_group = "En grupo",            cond_group_s = "Grupo",
    cond_instance = "En una instancia", cond_instance_s = "Instancia",
    cond_resting = "Descansando (posada o ciudad)", cond_resting_s = "Descansando",
    cond_mounted = "Montado",           cond_mounted_s = "Montado",
    cond_flying = "Volando",            cond_flying_s = "Volando",
    cond_swimming = "Nadando",          cond_swimming_s = "Nadando",
    cond_moving = "En movimiento",      cond_moving_s = "Moviéndose",
    cond_still = "Quieto",              cond_still_s = "Quieto",
    cond_cursor = "Arrastrando un hechizo u objeto", cond_cursor_s = "Arrastrando",
    st_notShown = "no se muestra ahora",
    st_edit = "Modo Edición",
    st_showing = "mostrándose", st_waiting = "esperando",
    st_pending = " (cambio de mouse pendiente hasta salir de combate)",
    st_found = "%d encontrados",
    blockClicks = "Sin clics en lo invisible en combate",
    needsAddon = "%s (necesita %s)",
    getAddon = "Necesita el addon %s, disponible en CurseForge. Sin él, esta opción aparece en gris.",
    blockClicks_tip = "El juego no deja que los addons cambien qué se puede clickear durante el combate, así que se decide cuando empieza. "
        .. "Activado: un elemento invisible al empezar el combate no se puede clickear hasta que termine, aunque aparezca (por ejemplo con el mouse). "
        .. "Desactivado: se puede clickear durante todo el combate, aunque esté invisible. Los atajos de teclado siempre funcionan. Fuera de combate, los elementos invisibles nunca se pueden clickear.",
})

---------------------------------------------------------------------------
-- Conditions
---------------------------------------------------------------------------
-- Asks the game something. Errors, missing functions and secret answers
-- count as "no".
local function Ask(f, ...)
    if not f then return false end
    local ok, v = pcall(f, ...)
    if not ok or ns.IsSecret(v) then return false end
    return v and true or false
end

local function InCombat()
    return InCombatLockdown() or Ask(UnitAffectingCombat, "player")
end

local function Moving() return Ask(IsPlayerMoving) end

-- "hover" is answered by each element (the mouse over that element); the
-- others are about the player and the same for every element.
local CONDITIONS = {
    { key = "hover" },
    { key = "combat",   test = InCombat },
    { key = "nocombat", test = function() return not InCombat() end },
    { key = "target",   test = function() return Ask(UnitExists, "target") end },
    { key = "enemy",    test = function() return Ask(UnitCanAttack, "player", "target") end },
    { key = "group",    test = function() return Ask(IsInGroup) end },
    { key = "instance", test = function()
        local ok, inside, kind = pcall(IsInInstance)
        return ok and inside == true and kind ~= "none"
    end },
    { key = "resting",  test = function() return Ask(IsResting) end },
    { key = "mounted",  test = function() return Ask(IsMounted) end },
    { key = "flying",   test = function() return Ask(IsFlying) end },
    { key = "swimming", test = function() return Ask(IsSwimming) end },
    { key = "moving",   test = Moving },
    { key = "still",    test = function() return not Moving() end },
    { key = "cursor",   test = function() return Ask(GetCursorInfo) end },
}

-- Shared with modules that have their own engine (PRD).
ns.CONDITIONS = CONDITIONS
ns.HOVER_LINGER = LINGER

local condCache, condCacheTime = {}, -1

-- True if the player condition is true now. Answers are kept for the rest
-- of the tick.
local function ConditionTrue(cond, now)
    if now ~= condCacheTime then
        wipe(condCache)
        condCacheTime = now
    end
    local v = condCache[cond.key]
    if v == nil then
        v = cond.test() and true or false
        condCache[cond.key] = v
    end
    return v
end
ns.ConditionTrue = ConditionTrue

---------------------------------------------------------------------------
-- Element dropdown
---------------------------------------------------------------------------
-- A label with a menu for one element: Shown and Hidden as choices, the
-- Show when conditions as checkboxes, and two submenus for the opacity.
-- "api" gives the element's current settings and how to change them:
--   summary(), mode(), setMode(v), hasCond(c), toggleCond(c),
--   alphaOn(), alphaOff(), setAlphaOn(v), setAlphaOff(v)
--   optional: enabled() (false greys it out), tooltip (text for the label)
-- Uses the game's current menu (WowStyle1DropdownTemplate), or the older
-- UIDropDownMenu if this client doesn't have it.
local visibilityDropdownCount = 0

function ns.CreateVisibilityDropdown(parent, label, y, api)
    local text = ns.RowLabel(parent, label, y)
    if api.tooltip then ns.AttachTooltip(parent, text, label, api.tooltip) end
    local rule = ns.ModuleRule({ enabledIf = api.enabled })
    local function On()
        local on = not rule.enabledIf or (rule.enabledIf() and true or false)
        if on then text:SetTextColor(1, 1, 1) else text:SetTextColor(0.5, 0.5, 0.5) end
        return on
    end

    local ok, dropdown = pcall(CreateFrame, "DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    if ok and dropdown and dropdown.SetupMenu then
        dropdown:SetWidth(170)
        dropdown:SetPoint("TOPLEFT", ns.CONTROL_X, y + 6)
        -- Keeps the menu open after ticking a box or picking an opacity.
        local KEEP_OPEN = MenuResponse and MenuResponse.Refresh

        dropdown:SetupMenu(function(_, root)
            for _, mode in ipairs({ "shown", "hidden" }) do
                root:CreateRadio(L[mode],
                    function() return api.mode() == mode end,
                    function() api.setMode(mode) end)
            end
            root:CreateDivider()
            root:CreateTitle(L.showWhen)
            for _, cond in ipairs(CONDITIONS) do
                root:CreateCheckbox(L["cond_" .. cond.key],
                    function() return api.hasCond(cond.key) end,
                    function() api.toggleCond(cond.key); return KEEP_OPEN end)
            end
            root:CreateDivider()
            local onMenu = root:CreateButton(string.format(L.alphaOnMenu, api.alphaOn()))
            for _, v in ipairs(ALPHA_ON_VALUES) do
                onMenu:CreateRadio(v .. "%",
                    function() return api.alphaOn() == v end,
                    function() api.setAlphaOn(v) end)
            end
            local offMenu = root:CreateButton(string.format(L.alphaOffMenu, api.alphaOff()))
            for _, v in ipairs(ALPHA_OFF_VALUES) do
                offMenu:CreateRadio(v .. "%",
                    function() return api.alphaOff() == v end,
                    function() api.setAlphaOff(v) end)
            end
        end)

        -- The button shows the summary instead of the list of ticked items.
        local custom = dropdown.SetSelectionText
            and pcall(dropdown.SetSelectionText, dropdown, function() return api.summary() end)
        local function ShowSummary()
            if not custom and dropdown.Text then dropdown.Text:SetText(api.summary()) end
        end
        -- Rebuilt when the menu closes, so the summary follows the changes.
        if dropdown.RegisterCallback and DropdownButtonMixin and DropdownButtonMixin.Event
            and DropdownButtonMixin.Event.OnMenuClose then
            pcall(dropdown.RegisterCallback, dropdown, DropdownButtonMixin.Event.OnMenuClose, function()
                dropdown:GenerateMenu()
                ShowSummary()
            end, dropdown)
        end
        return function()
            dropdown:GenerateMenu()
            ShowSummary()
            dropdown:SetEnabled(On())
        end
    end

    visibilityDropdownCount = visibilityDropdownCount + 1
    local legacy = CreateFrame("Frame", "UIVisibilityElementDropdown" .. visibilityDropdownCount, parent, "UIDropDownMenuTemplate")
    legacy:SetPoint("TOPLEFT", ns.CONTROL_X - 16, y + 8)
    UIDropDownMenu_SetWidth(legacy, 160)
    local function ShowSummary() UIDropDownMenu_SetText(legacy, api.summary()) end
    UIDropDownMenu_Initialize(legacy, function(_, level, menuList)
        level = level or 1
        if level == 1 then
            for _, mode in ipairs({ "shown", "hidden" }) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = L[mode]
                info.checked = api.mode() == mode
                info.func = function() api.setMode(mode); ShowSummary() end
                UIDropDownMenu_AddButton(info, level)
            end
            local title = UIDropDownMenu_CreateInfo()
            title.text = L.showWhen
            title.isTitle = true
            title.notCheckable = true
            UIDropDownMenu_AddButton(title, level)
            for _, cond in ipairs(CONDITIONS) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = L["cond_" .. cond.key]
                info.isNotRadio = true
                info.keepShownOnClick = true
                info.checked = api.hasCond(cond.key)
                info.func = function() api.toggleCond(cond.key); ShowSummary() end
                UIDropDownMenu_AddButton(info, level)
            end
            for _, sub in ipairs({ "on", "off" }) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = sub == "on" and string.format(L.alphaOnMenu, api.alphaOn())
                    or string.format(L.alphaOffMenu, api.alphaOff())
                info.hasArrow = true
                info.notCheckable = true
                info.menuList = sub
                UIDropDownMenu_AddButton(info, level)
            end
        else
            local values = menuList == "on" and ALPHA_ON_VALUES or ALPHA_OFF_VALUES
            local get = menuList == "on" and api.alphaOn or api.alphaOff
            local set = menuList == "on" and api.setAlphaOn or api.setAlphaOff
            for _, v in ipairs(values) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = v .. "%"
                info.checked = get() == v
                info.func = function() set(v); ShowSummary(); CloseDropDownMenus() end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)
    return function()
        ShowSummary()
        if On() then UIDropDownMenu_EnableDropDown(legacy) else UIDropDownMenu_DisableDropDown(legacy) end
    end
end

---------------------------------------------------------------------------
-- Condition list dropdown
---------------------------------------------------------------------------
-- A label with a menu holding every condition as a checkbox and an opacity
-- submenu. Used where a list of conditions is an extra layer on top of a
-- module's own rules (the PRD's Also show when and Also hide when).
-- "api": has(c), toggle(c), alpha(), setAlpha(v), alphaValues (list of
-- percents), alphaLabel (text with %d for the current opacity).
local conditionDropdownCount = 0

local function ConditionSummary(api)
    local names = {}
    for _, cond in ipairs(CONDITIONS) do
        if api.has(cond.key) then names[#names + 1] = L["cond_" .. cond.key .. "_s"] end
    end
    if #names == 0 then return L.cond_off end
    local text = names[1]
    if #names > 1 then text = string.format(L.cond_more, names[1], #names - 1) end
    return text .. string.format(" (%d%%)", api.alpha())
end

function ns.CreateConditionDropdown(parent, label, y, api)
    local text = ns.RowLabel(parent, label, y)
    if api.tooltip then ns.AttachTooltip(parent, text, label, api.tooltip) end
    local rule = ns.ModuleRule({})
    local function On()
        local on = not rule.enabledIf or (rule.enabledIf() and true or false)
        if on then text:SetTextColor(1, 1, 1) else text:SetTextColor(0.5, 0.5, 0.5) end
        return on
    end

    local ok, dropdown = pcall(CreateFrame, "DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    if ok and dropdown and dropdown.SetupMenu then
        dropdown:SetWidth(190)
        dropdown:SetPoint("TOPLEFT", ns.CONTROL_X, y + 6)
        local KEEP_OPEN = MenuResponse and MenuResponse.Refresh
        dropdown:SetupMenu(function(_, root)
            for _, cond in ipairs(CONDITIONS) do
                root:CreateCheckbox(L["cond_" .. cond.key],
                    function() return api.has(cond.key) end,
                    function() api.toggle(cond.key); return KEEP_OPEN end)
            end
            root:CreateDivider()
            local sub = root:CreateButton(string.format(api.alphaLabel, api.alpha()))
            for _, v in ipairs(api.alphaValues) do
                sub:CreateRadio(v .. "%",
                    function() return api.alpha() == v end,
                    function() api.setAlpha(v) end)
            end
        end)
        local custom = dropdown.SetSelectionText
            and pcall(dropdown.SetSelectionText, dropdown, function() return ConditionSummary(api) end)
        local function ShowSummary()
            if not custom and dropdown.Text then dropdown.Text:SetText(ConditionSummary(api)) end
        end
        if dropdown.RegisterCallback and DropdownButtonMixin and DropdownButtonMixin.Event
            and DropdownButtonMixin.Event.OnMenuClose then
            pcall(dropdown.RegisterCallback, dropdown, DropdownButtonMixin.Event.OnMenuClose, function()
                dropdown:GenerateMenu()
                ShowSummary()
            end, dropdown)
        end
        return function()
            dropdown:GenerateMenu()
            ShowSummary()
            dropdown:SetEnabled(On())
        end
    end

    conditionDropdownCount = conditionDropdownCount + 1
    local legacy = CreateFrame("Frame", "UIVisibilityConditionDropdown" .. conditionDropdownCount, parent, "UIDropDownMenuTemplate")
    legacy:SetPoint("TOPLEFT", ns.CONTROL_X - 16, y + 8)
    UIDropDownMenu_SetWidth(legacy, 180)
    local function ShowSummary() UIDropDownMenu_SetText(legacy, ConditionSummary(api)) end
    UIDropDownMenu_Initialize(legacy, function(_, level)
        level = level or 1
        if level == 1 then
            for _, cond in ipairs(CONDITIONS) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = L["cond_" .. cond.key]
                info.isNotRadio = true
                info.keepShownOnClick = true
                info.checked = api.has(cond.key)
                info.func = function() api.toggle(cond.key); ShowSummary() end
                UIDropDownMenu_AddButton(info, level)
            end
            local info = UIDropDownMenu_CreateInfo()
            info.text = string.format(api.alphaLabel, api.alpha())
            info.hasArrow = true
            info.notCheckable = true
            info.menuList = "alpha"
            UIDropDownMenu_AddButton(info, level)
        else
            for _, v in ipairs(api.alphaValues) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = v .. "%"
                info.checked = api.alpha() == v
                info.func = function() api.setAlpha(v); ShowSummary(); CloseDropDownMenus() end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)
    return function()
        ShowSummary()
        if On() then UIDropDownMenu_EnableDropDown(legacy) else UIDropDownMenu_DisableDropDown(legacy) end
    end
end

-- Combat start and end, for every module made with this engine.
-- PLAYER_REGEN_DISABLED fires right before combat lockdown starts, so
-- protected frames can still be changed there.
local combatEvents = CreateFrame("Frame")
combatEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
combatEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
combatEvents:SetScript("OnEvent", function(_, event)
    for _, m in ipairs(ns.elementModules) do
        if event == "PLAYER_REGEN_DISABLED" then
            if m.OnCombatStart then m.OnCombatStart() end
        elseif m.OnCombatEnd then
            m.OnCombatEnd()
        end
    end
end)

-- Every module made with this engine, in load order (used by Hover groups).
ns.elementModules = {}
-- "module.element" -> time until which that element counts as hovered.
-- Filled by every module, read by Hover groups to show elements together
-- across modules.
ns.elementHover = {}

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
        elements = cfg.elements,
    }
    -- Settings of the Show when mode, per element: conditions[key] is a set
    -- of condition keys; alphaOn and alphaOff are percents (100 and 0 when
    -- not set).
    cfg.defaults.conditions = cfg.defaults.conditions or {}
    cfg.defaults.alphaOn = cfg.defaults.alphaOn or {}
    cfg.defaults.alphaOff = cfg.defaults.alphaOff or {}
    if cfg.defaults.blockClicks == nil then cfg.defaults.blockClicks = true end

    -- Each element's id across modules, for example "actionbars.bar1".
    for _, element in ipairs(cfg.elements) do
        element.id = cfg.key .. "." .. element.key
    end

    local frameLists = {}   -- element key -> list of frames
    local managed = {}      -- frame -> element key
    local released = {}     -- frame -> true when the game has it back
    local mouseState = {}   -- frame -> last mouse state applied
    local disabledParts = {}
    local hooked = {}
    local dirty = true
    local applying = false
    local hoverUntil = {}   -- element key -> time it stops counting as hovered
    local combatMouse = {}  -- element key -> mouse chosen for the current fight
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

    local function Conds(key)
        local c = mod.db.conditions[key]
        if not c then
            c = {}
            mod.db.conditions[key] = c
        end
        return c
    end
    local function AlphaOn(key) return mod.db.alphaOn[key] or 100 end
    local function AlphaOff(key) return mod.db.alphaOff[key] or 0 end

    local function UsesHover(key)
        return mod.db.modes[key] == "custom" and Conds(key).hover or false
    end

    -- Old saved settings: "hover" becomes Show when with "Mouse over it".
    local function Migrate()
        for key, mode in pairs(mod.db.modes) do
            if mode == "hover" then
                mod.db.modes[key] = "custom"
                Conds(key).hover = true
            elseif mode ~= "shown" and mode ~= "hidden" and mode ~= "custom" then
                mod.db.modes[key] = "shown"
            end
        end
    end

    -- Short description of an element's setting, for its dropdown and the
    -- status: "Shown", "Hidden", "On hover (50%)", "In combat +2"...
    local function Summary(key)
        local mode = mod.db.modes[key]
        if mode == "shown" then return L.shown end
        if mode == "hidden" then return L.hidden end
        local names = {}
        for _, cond in ipairs(CONDITIONS) do
            if Conds(key)[cond.key] then names[#names + 1] = L["cond_" .. cond.key .. "_s"] end
        end
        local text
        if #names == 0 then
            text = L.cond_none
        elseif #names == 1 then
            text = names[1]
        else
            text = string.format(L.cond_more, names[1], #names - 1)
        end
        local on, off = AlphaOn(key), AlphaOff(key)
        if off > 0 and on < 100 then
            text = text .. string.format(" (%d-%d%%)", off, on)
        elseif off > 0 then
            text = text .. string.format(" (%d%%)", off)
        elseif on < 100 then
            text = text .. string.format(" (%d%%)", on)
        end
        return text
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
            local mode = db.modes[element.key]
            -- Elements that don't show on hover are only checked when
            -- they're part of a hover group: hovering them shows the rest of
            -- the group.
            local isHover = UsesHover(element.key)
            if isHover or (mode ~= "hidden" and ns.IsGroupTrigger and ns.IsGroupTrigger(element.id)) then
                for _, frame in ipairs(GetFrames(element)) do
                    if ns.IsCursorOver(frame) then
                        ns.elementHover[element.id] = now + LINGER
                        if isHover then
                            hoverUntil[element.key] = now + LINGER
                            any = true
                        end
                        break
                    end
                end
            end
        end
        if any then groupUntil = now + LINGER end
    end

    -- True if the mouse (or a linked element, the minimap or a hover group)
    -- asks for the element to show.
    local function Hovered(element, now)
        local db = mod.db
        if now < (hoverUntil[element.key] or 0) then return true end
        if db.linkHover and now < groupUntil then return true end
        if cfg.minimapHover and db.minimapHover and now < minimapUntil then return true end
        if ns.GroupShows and ns.GroupShows(element.id, now) then return true end
        return false
    end

    -- Show when mode: true if any of the element's conditions is true.
    -- "asCombat" answers as if combat had already started (used right
    -- before it does).
    local function ConditionsMet(element, now, asCombat)
        local conds = Conds(element.key)
        for _, cond in ipairs(CONDITIONS) do
            if conds[cond.key] then
                if asCombat and (cond.key == "combat" or cond.key == "nocombat") then
                    if cond.key == "combat" then return true end
                elseif cond.test then
                    if ConditionTrue(cond, now) then return true end
                elseif Hovered(element, now) then
                    return true
                end
            end
        end
        return false
    end

    -- Returns opacity, mouse, and whether the element goes back to the game.
    local function Targets(element, now)
        local db = mod.db
        if ElementReleased(element.key) then return 1, true, true end
        if element.forceShow and element.forceShow() then return 1, true, false end
        if db.modes[element.key] == "hidden" then return 0, false, false end
        -- Show when: clickable only while it can be seen. In combat, the
        -- mouse chosen when the fight started.
        local alpha = ConditionsMet(element, now) and AlphaOn(element.key) or AlphaOff(element.key)
        local mouse = alpha > 0
        if InCombatLockdown() and combatMouse[element.key] ~= nil then mouse = combatMouse[element.key] end
        return alpha / 100, mouse, false
    end

    -- Applies the targets to one frame. Returns true if work remains.
    local function ApplyMouse(frame, mouse)
        local last = mouseState[frame]
        if last == nil then last = true end
        if last == mouse then return true end
        if IsLocked(frame) then return false end
        if mouse then RestoreMouse(frame) else DisableMouse(frame) end
        mouseState[frame] = mouse
        return true
    end

    -- Right before combat (protected frames can still change): chooses each
    -- Show when element's mouse for the fight. See the top of this file.
    function mod.OnCombatStart()
        wipe(combatMouse)
        local db = mod.db
        if not db or not db.enabled or ns.IsEditMode() then return end
        local now = GetTime()
        for _, element in ipairs(cfg.elements) do
            local key = element.key
            if db.modes[key] == "custom" then
                local mouse
                if (element.forceShow and element.forceShow()) or AlphaOff(key) > 0
                    or ConditionsMet(element, now, true) then
                    mouse = true
                elseif db.blockClicks then
                    mouse = false
                else
                    -- Clickable if something other than "out of combat" can
                    -- show it during the fight.
                    mouse = false
                    for c, on in pairs(Conds(key)) do
                        if on and c ~= "nocombat" then mouse = true end
                    end
                end
                combatMouse[key] = mouse
                for _, frame in ipairs(GetFrames(element)) do ApplyMouse(frame, mouse) end
            end
        end
        dirty = true
    end

    function mod.OnCombatEnd()
        wipe(combatMouse)
        dirty = true
    end

    local function UpdateFrame(frame, alpha, mouse, release)
        if release and released[frame] then return false end
        if not release then released[frame] = nil end

        applying = true
        local busy = ns.Fade(frame, alpha)
        applying = false

        if not ApplyMouse(frame, mouse) then busy = true end

        if release and not busy then released[frame] = true end
        return busy
    end

    -- True while the module has to check things on every tick.
    local function NeedsPolling()
        local db = mod.db
        if not db.enabled then return false end
        if cfg.minimapHover and db.minimapHover then return true end
        if ns.ModuleInGroups and ns.ModuleInGroups(cfg.key) then return true end
        for _, element in ipairs(cfg.elements) do
            local mode = db.modes[element.key]
            if mode == "custom" then return true end
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
        Migrate()
        mod.RefreshLists(true)
    end

    function mod.SetEnabled(v)
        mod.db.enabled = v
        dirty = true
    end

    function mod.BuildOptions(parent, y)
        local refreshers = {}
        local function add(r) refreshers[#refreshers + 1] = r end
        local function refreshAll() for _, r in ipairs(refreshers) do r() end end
        -- Everything below is greyed out while the module is off.
        local function isOn() return mod.db.enabled end

        add(ns.CreateCheck(parent, L.enabled, y,
            function() return mod.db.enabled end, function(v) mod.SetEnabled(v); refreshAll() end, { master = true }))
        y = y - 40

        ns.CreateSection(parent, L.sec_elements, y)
        y = y - 30
        for _, element in ipairs(cfg.elements) do
            -- An element of another addon (element.requires = its folder name) says so, and is greyed out without it.
            local label = L[element.label]
            if element.requires then label = string.format(L.needsAddon, label, element.requiresName or element.requires) end
            -- What the modes do, plus the module's own note, in the tooltip instead of on the page.
            local tip = L.modesNote
            if cfg.noteKey and not cfg.showNote then tip = tip .. "\n\n" .. L[cfg.noteKey] end
            if element.requires then
                tip = string.format(L.getAddon, element.requiresName or element.requires) .. "\n\n" .. tip
            end
            add(ns.CreateVisibilityDropdown(parent, label, y, {
                enabled = function()
                    return isOn() and (not element.requires or ns.IsAddOnLoaded(element.requires))
                end,
                tooltip = tip,
                summary = function() return Summary(element.key) end,
                mode = function() return mod.db.modes[element.key] end,
                setMode = function(v) mod.db.modes[element.key] = v; dirty = true end,
                hasCond = function(c) return mod.db.modes[element.key] == "custom" and Conds(element.key)[c] or false end,
                toggleCond = function(c)
                    -- Ticking a condition from Shown or Hidden starts a new list.
                    if mod.db.modes[element.key] ~= "custom" then
                        wipe(Conds(element.key))
                        mod.db.modes[element.key] = "custom"
                    end
                    local conds = Conds(element.key)
                    conds[c] = not conds[c] or nil
                    dirty = true
                end,
                alphaOn = function() return AlphaOn(element.key) end,
                alphaOff = function() return AlphaOff(element.key) end,
                setAlphaOn = function(v) mod.db.alphaOn[element.key] = v ~= 100 and v or nil; dirty = true end,
                setAlphaOff = function(v) mod.db.alphaOff[element.key] = v ~= 0 and v or nil; dirty = true end,
            }))
            y = y - 32
        end
        -- A note stays on the page only where it's needed to use it (cfg.showNote).
        if cfg.noteKey and cfg.showNote then y = y - 4 - ns.CreateNote(parent, L[cfg.noteKey], y - 4) - 12 end
        y = y - 20

        ns.CreateSection(parent, L.sec_options, y)
        y = y - 32
        add(ns.CreateCheck(parent, L.linkHover, y,
            function() return mod.db.linkHover end, function(v) mod.db.linkHover = v; dirty = true end,
            { tooltip = L.linkHover_tip, enabledIf = isOn }))
        y = y - 28
        add(ns.CreateCheck(parent, L.blockClicks, y,
            function() return mod.db.blockClicks end, function(v) mod.db.blockClicks = v; dirty = true end,
            { tooltip = L.blockClicks_tip, width = 360, enabledIf = isOn }))
        y = y - 28
        -- Options of one module only (cfg.extraOptions returns the new y).
        if cfg.extraOptions then
            y = cfg.extraOptions(parent, y, add, function() dirty = true end, isOn)
        end
        if cfg.minimapHover then
            add(ns.CreateCheck(parent, L[cfg.minimapHoverLabel], y,
                function() return mod.db.minimapHover end, function(v) mod.db.minimapHover = v; dirty = true end,
                { tooltip = L.minimapHover_tip, enabledIf = isOn }))
            y = y - 28
        end


        return refreshAll
    end

    function mod.PrintStatus()
        local now = GetTime()
        for _, element in ipairs(cfg.elements) do
            local frames = GetFrames(element)
            local frame = frames[1]
            local mode = Summary(element.key)
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
                if mod.db.modes[element.key] == "custom" then
                    detail = detail .. ", " .. (ConditionsMet(element, now) and L.st_showing or L.st_waiting)
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
    ns.elementModules[#ns.elementModules + 1] = mod
    return mod
end