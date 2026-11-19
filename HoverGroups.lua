-- UI Visibility: hover groups module
-- Elements from different modules that show together on hover. Each group
-- holds any elements of the Action bars, Class bars, Unit frames, Interface
-- and Minimap modules. Hovering any element of a group shows every element
-- of that group that has "Mouse over it" ticked in Show when.
--
-- Other elements can be part of a group too: hovering them shows the rest
-- of the group (for example, hovering the player frame shows the action
-- bars). Elements in Hidden mode stay hidden and don't show the group.
--
-- The element engine does the work: each module records which of its
-- elements are hovered in ns.elementHover, and asks ns.GroupShows whether a
-- group wants an element shown.

local ADDON_NAME, ns = ...
local L = ns.Lproxy

local NUM_GROUPS = 4

ns.AddLocale("en", {
    tab_groups = "Hover groups",
    hg_title = "Hover Groups",
    desc_groups = "Show elements from different modules together on hover.",
    hg_note = "Hovering any element of a group shows the ones with \"Mouse over it\" ticked. Hidden elements stay hidden. A group needs two or more.",
    hg_secGroup = "Group",
    hg_editing = "Group to edit",
    hg_count = "Elements in this group: %d",
    hg_clear = "Clear",
    hg_secElements = "Elements in the group",
    hg_group1 = "Group 1", hg_group2 = "Group 2", hg_group3 = "Group 3", hg_group4 = "Group 4",
    hg_statusGroup = "Group %d: %s",
    hg_statusNone = "no groups with two or more elements.",
})
ns.AddLocale("es", {
    tab_groups = "Grupos",
    hg_title = "Grupos al apuntar",
    desc_groups = "Muestra juntos elementos de distintos módulos al pasar el mouse.",
    hg_note = "Apuntar a cualquier elemento de un grupo muestra los que tienen \"Mouse encima\" marcado. Los ocultos siguen ocultos. Un grupo necesita dos o más.",
    hg_secGroup = "Grupo",
    hg_editing = "Grupo a editar",
    hg_count = "Elementos en este grupo: %d",
    hg_clear = "Vaciar",
    hg_secElements = "Elementos del grupo",
    hg_group1 = "Grupo 1", hg_group2 = "Grupo 2", hg_group3 = "Grupo 3", hg_group4 = "Grupo 4",
    hg_statusGroup = "Grupo %d: %s",
    hg_statusNone = "no hay grupos con dos o más elementos.",
})

local GROUP_KEYS = {}
local defaultGroups = {}
for i = 1, NUM_GROUPS do
    GROUP_KEYS[i] = "hg_group" .. i
    defaultGroups[i] = { members = {} } -- members["module.element"] = true
end

local mod = {
    key = "groups", titleKey = "hg_title", tabKey = "tab_groups",
    defaults = { enabled = true, groups = defaultGroups },
}

---------------------------------------------------------------------------
-- Which groups each element is in
---------------------------------------------------------------------------
-- Rebuilt when the groups change. Groups with fewer than two elements are
-- left out, since there's nothing to show together.
local groupsOf = {}   -- element id -> list of group numbers
local usedModules = {} -- module key -> true if one of its elements is in a group

local function Rebuild()
    groupsOf, usedModules = {}, {}
    if not mod.db then return end
    for i, group in ipairs(mod.db.groups) do
        local count = 0
        for _ in pairs(group.members) do count = count + 1 end
        if count >= 2 then
            for id in pairs(group.members) do
                groupsOf[id] = groupsOf[id] or {}
                table.insert(groupsOf[id], i)
                usedModules[id:match("^[^.]+")] = true
            end
        end
    end
end

local function Changed()
    Rebuild()
    for _, m in ipairs(ns.elementModules) do m.MarkDirty() end
end

-- Called by the element engine.
function ns.IsGroupTrigger(id)
    return mod.db and mod.db.enabled and groupsOf[id] ~= nil
end

function ns.ModuleInGroups(moduleKey)
    return mod.db and mod.db.enabled and usedModules[moduleKey] or false
end

function ns.GroupShows(id, now)
    if not (mod.db and mod.db.enabled) then return false end
    local list = groupsOf[id]
    if not list then return false end
    for _, i in ipairs(list) do
        for member in pairs(mod.db.groups[i].members) do
            if (ns.elementHover[member] or 0) > now then return true end
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Module
---------------------------------------------------------------------------
function mod.OnLogin()
    Rebuild()
end

function mod.SetEnabled(v)
    mod.db.enabled = v
    Changed()
end

-- Name of an element, like "Action Bar 1" or "Clock".
local function ElementName(id)
    for _, m in ipairs(ns.elementModules) do
        for _, element in ipairs(m.elements) do
            if element.id == id then return L[element.label] end
        end
    end
end

function mod.PrintStatus()
    local any = false
    for i, group in ipairs(mod.db.groups) do
        local names = {}
        for id in pairs(group.members) do
            local name = ElementName(id)
            if name then names[#names + 1] = name end
        end
        if #names >= 2 then
            table.sort(names)
            ns.Print(string.format(L.hg_statusGroup, i, table.concat(names, ", ")))
            any = true
        end
    end
    if not any then ns.Print(L.hg_title .. ": " .. L.hg_statusNone) end
end

---------------------------------------------------------------------------
-- Options
---------------------------------------------------------------------------
local COL1, COL2, WIDTH = 16, 220, 170

function mod.BuildOptions(parent, y)
    local refreshers = {}
    local function add(r) refreshers[#refreshers + 1] = r end
    local function refreshAll() for _, r in ipairs(refreshers) do r() end end
    local selected = 1
    local function members() return mod.db.groups[selected].members end
    local function isOn() return mod.db.enabled end

    add(ns.CreateCheck(parent, L.enabled, y,
        function() return mod.db.enabled end,
        function(v) mod.SetEnabled(v); refreshAll() end))
    y = y - 40
    y = y - ns.CreateNote(parent, L.hg_note, y) - 16

    -- Group picker, element count and Clear button.
    ns.CreateSection(parent, L.hg_secGroup, y)
    y = y - 36
    add(ns.CreateDropdown(parent, L.hg_editing, y, GROUP_KEYS,
        function() return GROUP_KEYS[selected] end,
        function(v)
            for i, key in ipairs(GROUP_KEYS) do
                if key == v then selected = i end
            end
            refreshAll()
        end))
    y = y - 32

    local count = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    count:SetPoint("TOPLEFT", 20, y)
    add(function()
        local n = 0
        for _ in pairs(members()) do n = n + 1 end
        count:SetText(string.format(L.hg_count, n))
    end)

    local clear = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    clear:SetSize(100, 22)
    clear:SetPoint("TOPLEFT", 196, y + 4)
    clear:SetText(L.hg_clear)
    clear:SetScript("OnClick", function()
        wipe(members())
        Changed()
        refreshAll()
    end)
    add(function() clear:SetEnabled(isOn()) end)
    y = y - 34

    -- One checkbox per element, under the name of its module.
    ns.CreateSection(parent, L.hg_secElements, y)
    y = y - 34
    for _, m in ipairs(ns.elementModules) do
        ns.CreateHeader(parent, L[m.titleKey], y)
        y = y - 22
        for i, element in ipairs(m.elements) do
            local col = (i - 1) % 2
            local id = element.id
            add(ns.CreateCheck(parent, L[element.label], y,
                function() return members()[id] or false end,
                function(v)
                    members()[id] = v or nil
                    Changed()
                    refreshAll()
                end,
                { x = col == 0 and COL1 or COL2, width = WIDTH, enabledIf = isOn }))
            if col == 1 or i == #m.elements then y = y - 26 end
        end
        y = y - 10
    end

    return refreshAll
end

ns.RegisterModule(mod)
