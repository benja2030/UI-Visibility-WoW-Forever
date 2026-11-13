-- UI Visibility: core
-- Shared settings, texts, helpers, options window, help window, update loop
-- and slash commands. Each part of the interface is a module in its own file.

local ADDON_NAME, ns = ...

ns.PREFIX = "|cff33ff99UI Visibility:|r "
ns.ICON = "Interface\\AddOns\\UIVisibility\\Media\\Icon"
ns.TICK = 0.05      -- fast update interval (seconds), shared by all modules
ns.SLOW_TICK = 5    -- slow update interval (seconds)
ns.FADE_TIME = 0.2  -- duration of fades (seconds)

ns.moduleList = {}
ns.moduleByKey = {}

function ns.RegisterModule(mod)
    ns.moduleList[#ns.moduleList + 1] = mod
    ns.moduleByKey[mod.key] = mod
end

---------------------------------------------------------------------------
-- Texts
---------------------------------------------------------------------------
ns.LOCALES = { en = {}, es = {} }
ns.L = ns.LOCALES.en

function ns.AddLocale(lang, strings)
    for k, v in pairs(strings) do ns.LOCALES[lang][k] = v end
end

-- Modules read texts through this table, so they always get the current
-- language even though they load before the settings.
ns.Lproxy = setmetatable({}, {
    __index = function(_, k) return ns.L[k] or ns.LOCALES.en[k] or k end,
})
local L = ns.Lproxy

ns.AddLocale("en", {
    loaded = "active. Type /uiv to open the options.",
    oldAddon = "|cffff8800%s is also enabled.|r UI Visibility already includes it, so disable it in the AddOns list to avoid conflicts.",
    enabled = "Enabled",
    modules = "Modules:",
    subtitle = "Controls when parts of the interface are visible.",
    languageLabel = "Language:",
    langReload = "language changed. Type /reload to apply it.",
    langPopup = "The language changes after reloading the interface. Reload now?",
    reloadNow = "Reload",
    later = "Later",
    help = "Help",
    shown = "Shown", hidden = "Hidden", hover = "On hover",
    notFound = "not found",
    helpTitle = "UI Visibility - Help",
    helpText = "If UI Visibility stops loading after a WoW: Forever update:\n\n"
        .. "1. At character select, open the AddOns list.\n\n"
        .. "2. If the addon says |cffffd100Out of date|r, check |cffffd100Load out of date AddOns|r at the top of the list. That's all.\n\n"
        .. "3. If it says |cffffd100Incompatible|r, enter the game and type the command below in chat. It prints a number.\n\n"
        .. "4. Open |cffffd100UIVisibility.toc|r (in Interface\\AddOns\\UIVisibility) with Notepad and replace the number in the first line:\n"
        .. "     ## Interface: (the number)\n\n"
        .. "5. Save the file and restart the game.",
    helpCopy = "Click the box and press Ctrl+C to copy the command.",
    helpFooter = "If the addon doesn't load you can't open this window, so these steps are also in README.txt inside the addon folder.",
    commands = "commands: /uiv, /uiv prd, /uiv xp, /uiv bars, /uiv minimap, /uiv options, /uiv help, /uiv status",
})
ns.AddLocale("es", {
    loaded = "activo. Escribe /uiv para abrir las opciones.",
    oldAddon = "|cffff8800%s también está activado.|r UI Visibility ya lo incluye, así que desactívalo en la lista de AddOns para evitar conflictos.",
    enabled = "Activado",
    modules = "Módulos:",
    subtitle = "Controla cuándo se ven las partes de la interfaz.",
    languageLabel = "Idioma:",
    langReload = "idioma cambiado. Escribe /reload para aplicarlo.",
    langPopup = "El idioma cambia al recargar la interfaz. ¿Recargar ahora?",
    reloadNow = "Recargar",
    later = "Más tarde",
    help = "Ayuda",
    shown = "Visible", hidden = "Oculta", hover = "Con el mouse",
    notFound = "no encontrado",
    helpTitle = "UI Visibility - Ayuda",
    helpText = "Si UI Visibility deja de cargar después de una actualización de WoW: Forever:\n\n"
        .. "1. En la selección de personaje, abre la lista de AddOns.\n\n"
        .. "2. Si el addon dice |cffffd100Out of date|r, marca |cffffd100Load out of date AddOns|r arriba de la lista. Con eso basta.\n\n"
        .. "3. Si dice |cffffd100Incompatible|r, entra al juego y escribe en el chat el comando de abajo. Te mostrará un número.\n\n"
        .. "4. Abre |cffffd100UIVisibility.toc|r (en Interface\\AddOns\\UIVisibility) con el Bloc de notas y reemplaza el número de la primera línea:\n"
        .. "     ## Interface: (el número)\n\n"
        .. "5. Guarda el archivo y reinicia el juego.",
    helpCopy = "Haz clic en el recuadro y presiona Ctrl+C para copiar el comando.",
    helpFooter = "Si el addon no carga no podrás abrir esta ventana, así que estos pasos también están en README.txt dentro de la carpeta del addon.",
    commands = "comandos: /uiv, /uiv prd, /uiv xp, /uiv bars, /uiv minimap, /uiv opciones, /uiv ayuda, /uiv estado",
})

function ns.Print(msg) print(ns.PREFIX .. msg) end

---------------------------------------------------------------------------
-- Helpers shared by the modules
---------------------------------------------------------------------------
function ns.IsEditMode()
    return EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive
        and EditModeManagerFrame:IsEditModeActive() and true or false
end

-- Finds an object by path, for example "MinimapCluster.Tracking".
function ns.Resolve(path)
    local obj = _G
    for part in path:gmatch("[^%.]+") do
        if type(obj) ~= "table" then return nil end
        obj = obj[part]
    end
    if type(obj) == "table" and obj.GetAlpha then return obj end
    return nil
end

local function EffectiveScale(obj)
    if obj.GetEffectiveScale then return obj:GetEffectiveScale() end
    local parent = obj:GetParent()
    return parent and parent:GetEffectiveScale() or 1
end

-- True if the cursor is inside the object's rectangle on screen. Calculated
-- directly because the game's MouseIsOver fails in Forever.
function ns.IsCursorOver(obj)
    if not obj:IsVisible() then return false end
    local left, bottom, width, height = obj:GetRect()
    if not left then return false end
    local x, y = GetCursorPosition()
    local scale = EffectiveScale(obj)
    x, y = x / scale, y / scale
    return x >= left and x <= left + width and y >= bottom and y <= bottom + height
end

-- Moves an object's opacity one step toward the target. Returns true while
-- the fade is still in progress.
function ns.Fade(obj, target)
    local current = obj:GetAlpha()
    local diff = target - current
    if math.abs(diff) < 0.001 then return false end
    local step = ns.TICK / ns.FADE_TIME
    if diff > step then diff = step elseif diff < -step then diff = -step end
    obj:SetAlpha(current + diff)
    return true
end

---------------------------------------------------------------------------
-- Option widgets shared by the modules
---------------------------------------------------------------------------
function ns.CreateCheck(parent, label, y, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 16, y)
    cb:SetSize(26, 26)
    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    text:SetText(label)
    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
    end)
    return function() cb:SetChecked(getter()) end
end

function ns.CreateHeader(parent, text, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", 18, y)
    fs:SetText(text)
end

function ns.CreateNote(parent, text, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    fs:SetPoint("TOPLEFT", 18, y)
    fs:SetWidth(320)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
end

function ns.CreateStepper(parent, label, y, getter, setter, minV, maxV, step, suffix)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", 18, y)
    text:SetText(label)

    local value = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("TOPLEFT", 220, y)
    value:SetJustifyH("CENTER")
    value:SetWidth(44)

    local function Refresh() value:SetText(getter() .. suffix) end

    local minus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    minus:SetSize(24, 20)
    minus:SetPoint("RIGHT", value, "LEFT", -2, 0)
    minus:SetText("-")
    minus:SetScript("OnClick", function()
        setter(math.max(minV, getter() - step)); Refresh()
    end)

    local plus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    plus:SetSize(24, 20)
    plus:SetPoint("LEFT", value, "RIGHT", 2, 0)
    plus:SetText("+")
    plus:SetScript("OnClick", function()
        setter(math.min(maxV, getter() + step)); Refresh()
    end)
    return Refresh
end

-- A label with a button that cycles through a list of values.
function ns.CreateCycle(parent, label, y, values, getter, setter)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", 18, y)
    text:SetText(label)

    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(130, 22)
    button:SetPoint("TOPLEFT", 196, y + 4)

    local function Refresh() button:SetText(L[getter()]) end
    button:SetScript("OnClick", function()
        local current, nextIndex = getter(), 1
        for i, v in ipairs(values) do
            if v == current then nextIndex = (i % #values) + 1 end
        end
        setter(values[nextIndex])
        Refresh()
    end)
    return Refresh
end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
local function ApplyDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then target[k] = {} end
            ApplyDefaults(target[k], v)
        elseif target[k] == nil then
            target[k] = v
        end
    end
end

local function InitDB()
    UIVisibilityDB = UIVisibilityDB or {}
    local db = UIVisibilityDB
    if db.language == nil then db.language = "en" end
    if db.lastTab == nil then db.lastTab = "prd" end
    db.modules = db.modules or {}
    for _, mod in ipairs(ns.moduleList) do
        db.modules[mod.key] = db.modules[mod.key] or {}
        ApplyDefaults(db.modules[mod.key], mod.defaults)
        mod.db = db.modules[mod.key]
    end
    ns.db = db
    ns.L = ns.LOCALES[db.language] or ns.LOCALES.en
end

---------------------------------------------------------------------------
-- Help window
---------------------------------------------------------------------------
local HELP_COMMAND = "/dump select(4, GetBuildInfo())"
local helpFrame

function ns.ShowHelp()
    if not helpFrame then
        helpFrame = CreateFrame("Frame", "UIVisibilityHelp", UIParent, "BasicFrameTemplateWithInset")
        helpFrame:SetWidth(400)
        helpFrame:SetPoint("CENTER")
        helpFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        helpFrame:SetMovable(true)
        helpFrame:EnableMouse(true)
        helpFrame:RegisterForDrag("LeftButton")
        helpFrame:SetScript("OnDragStart", helpFrame.StartMoving)
        helpFrame:SetScript("OnDragStop", helpFrame.StopMovingOrSizing)
        tinsert(UISpecialFrames, "UIVisibilityHelp")

        local title = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", 0, -6)
        title:SetText(L.helpTitle)

        local text = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOPLEFT", 18, -36)
        text:SetWidth(364)
        text:SetJustifyH("LEFT")
        text:SetText(L.helpText)

        local box = CreateFrame("EditBox", nil, helpFrame, "InputBoxTemplate")
        box:SetSize(300, 24)
        box:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 6, -14)
        box:SetAutoFocus(false)
        box:SetText(HELP_COMMAND)
        box:SetCursorPosition(0)
        box:SetScript("OnTextChanged", function(self, userInput)
            if userInput then self:SetText(HELP_COMMAND); self:HighlightText() end
        end)
        box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        local copy = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        copy:SetPoint("TOPLEFT", box, "BOTTOMLEFT", -6, -6)
        copy:SetWidth(364)
        copy:SetJustifyH("LEFT")
        copy:SetText(L.helpCopy)

        local footer = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        footer:SetPoint("TOPLEFT", copy, "BOTTOMLEFT", 0, -16)
        footer:SetWidth(364)
        footer:SetJustifyH("LEFT")
        footer:SetText(L.helpFooter)

        helpFrame:SetHeight(36 + text:GetStringHeight() + 14 + 24 + 6
            + copy:GetStringHeight() + 16 + footer:GetStringHeight() + 24)
    end
    helpFrame:Show()
end

-- Language dropdown and Help button, used at the bottom of the option pages.
-- Each language is listed in its own language, so it's easy to find.
local LANGUAGES = {
    { key = "en", name = "English" },
    { key = "es", name = "Español" },
}

local function LanguageName(key)
    for _, lang in ipairs(LANGUAGES) do
        if lang.key == key then return lang.name end
    end
    return key
end

-- Texts are built when a window is created, so a new language needs a
-- reload. The popup offers to do it right away.
local function AskReload()
    StaticPopupDialogs["UIVISIBILITY_RELOAD"] = {
        text = ns.LOCALES[ns.db.language].langPopup,
        button1 = ns.LOCALES[ns.db.language].reloadNow,
        button2 = ns.LOCALES[ns.db.language].later,
        OnAccept = function() ReloadUI() end,
        OnCancel = function() ns.Print(ns.LOCALES[ns.db.language].langReload) end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("UIVISIBILITY_RELOAD")
end

local function SetLanguage(key)
    if ns.db.language == key then return end
    ns.db.language = key
    AskReload()
end

local dropdownCount = 0

-- Uses the game's current dropdown (WowStyle1DropdownTemplate). If this
-- client doesn't have it, falls back to the older UIDropDownMenu.
local function CreateLanguageDropdown(parent, label)
    local ok, dropdown = pcall(CreateFrame, "DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    if ok and dropdown and dropdown.SetupMenu then
        dropdown:SetWidth(120)
        dropdown:SetPoint("LEFT", label, "RIGHT", 8, 0)
        dropdown:SetupMenu(function(_, root)
            for _, lang in ipairs(LANGUAGES) do
                root:CreateRadio(lang.name,
                    function() return ns.db.language == lang.key end,
                    function() SetLanguage(lang.key) end)
            end
        end)
        return
    end

    dropdownCount = dropdownCount + 1
    local legacy = CreateFrame("Frame", "UIVisibilityLanguageDropdown" .. dropdownCount, parent, "UIDropDownMenuTemplate")
    legacy:SetPoint("LEFT", label, "RIGHT", -8, -2)
    UIDropDownMenu_SetWidth(legacy, 110)
    UIDropDownMenu_SetText(legacy, LanguageName(ns.db.language))
    UIDropDownMenu_Initialize(legacy, function()
        for _, lang in ipairs(LANGUAGES) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = lang.name
            info.checked = ns.db.language == lang.key
            info.func = function()
                UIDropDownMenu_SetText(legacy, lang.name)
                SetLanguage(lang.key)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
end

local function CreateBottomButtons(parent, anchorPoint, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint(anchorPoint, x, y + 6)
    label:SetText(L.languageLabel)
    CreateLanguageDropdown(parent, label)

    local helpButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    helpButton:SetSize(86, 24)
    helpButton:SetPoint("LEFT", label, "LEFT", 220, 0)
    helpButton:SetText(L.help)
    helpButton:SetScript("OnClick", ns.ShowHelp)
end

---------------------------------------------------------------------------
-- Floating options window with one tab per module (/uiv)
---------------------------------------------------------------------------
local window
local tabs, panes, paneRefresh = {}, {}, {}

local function SelectTab(key)
    if not ns.moduleByKey[key] then key = ns.moduleList[1].key end
    ns.db.lastTab = key
    for k, button in pairs(tabs) do
        if k == key then button:LockHighlight() else button:UnlockHighlight() end
    end
    for k, pane in pairs(panes) do pane:SetShown(k == key) end
    if not panes[key] then
        local mod = ns.moduleByKey[key]
        local pane = CreateFrame("Frame", nil, window)
        pane:SetPoint("TOPLEFT", 0, -62)
        pane:SetPoint("BOTTOMRIGHT", 0, 44)
        paneRefresh[key] = mod.BuildOptions(pane, -4)
        pane:SetScript("OnShow", function() paneRefresh[key]() end)
        panes[key] = pane
    end
    paneRefresh[key]()
end

local function CreateWindow()
    window = CreateFrame("Frame", "UIVisibilityWindow", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(380, 600)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:Hide()
    tinsert(UISpecialFrames, "UIVisibilityWindow")

    local title = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 8, -6)
    title:SetText("UI Visibility")
    local icon = window:CreateTexture(nil, "OVERLAY")
    icon:SetSize(16, 16)
    icon:SetPoint("RIGHT", title, "LEFT", -4, 0)
    icon:SetTexture(ns.ICON)

    local width = (380 - 24 - (#ns.moduleList - 1) * 4) / #ns.moduleList
    for i, mod in ipairs(ns.moduleList) do
        local button = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
        button:SetSize(width, 24)
        button:SetPoint("TOPLEFT", 12 + (i - 1) * (width + 4), -30)
        button:SetText(L[mod.tabKey])
        button:SetScript("OnClick", function() SelectTab(mod.key) end)
        tabs[mod.key] = button
    end

    CreateBottomButtons(window, "BOTTOMLEFT", 16, 14)
end

function ns.OpenWindow(key)
    if not window then CreateWindow() end
    window:Show()
    SelectTab(key or ns.db.lastTab)
end

-- Called by the game when UI Visibility is clicked in the minimap's addon
-- button (declared in the .toc with AddonCompartmentFunc).
function UIVisibility_OnAddonCompartmentClick()
    if window and window:IsShown() then
        window:Hide()
    else
        ns.OpenWindow()
    end
end

---------------------------------------------------------------------------
-- Pages in the game's Options > AddOns
---------------------------------------------------------------------------
local function RegisterSettings()
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end

    local main = CreateFrame("Frame")
    main:Hide()
    local mainIcon = main:CreateTexture(nil, "OVERLAY")
    mainIcon:SetSize(32, 32)
    mainIcon:SetPoint("TOPLEFT", 16, -10)
    mainIcon:SetTexture(ns.ICON)
    local title = main:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", mainIcon, "RIGHT", 8, 0)
    title:SetText("UI Visibility")
    local subtitle = main:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", mainIcon, "BOTTOMLEFT", 0, -6)
    subtitle:SetText(L.subtitle)

    local refreshers = {}
    local y = -64
    ns.CreateHeader(main, L.modules, y)
    y = y - 24
    for _, mod in ipairs(ns.moduleList) do
        refreshers[#refreshers + 1] = ns.CreateCheck(main, L[mod.titleKey], y,
            function() return mod.db.enabled end, function(v) mod.SetEnabled(v) end)
        y = y - 28
    end
    CreateBottomButtons(main, "TOPLEFT", 18, y - 16)
    main:SetScript("OnShow", function() for _, r in ipairs(refreshers) do r() end end)

    ns.settingsCategory = Settings.RegisterCanvasLayoutCategory(main, "UI Visibility")

    if Settings.RegisterCanvasLayoutSubcategory then
        for _, mod in ipairs(ns.moduleList) do
            local page = CreateFrame("Frame")
            page:Hide()
            local pageTitle = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            pageTitle:SetPoint("TOPLEFT", 16, -16)
            pageTitle:SetText(L[mod.titleKey])
            page:SetScript("OnShow", mod.BuildOptions(page, -48))
            Settings.RegisterCanvasLayoutSubcategory(ns.settingsCategory, page, L[mod.titleKey])
        end
    end

    Settings.RegisterAddOnCategory(ns.settingsCategory)
end

local function OpenSettings()
    if ns.settingsCategory and Settings.OpenToCategory then
        local ok = pcall(Settings.OpenToCategory, ns.settingsCategory:GetID())
        if ok then return end
    end
    ns.OpenWindow()
end

---------------------------------------------------------------------------
-- Shared update loop
---------------------------------------------------------------------------
local lastEditMode = false

local function Tick()
    local editMode = ns.IsEditMode()
    local editChanged = editMode ~= lastEditMode
    lastEditMode = editMode
    local now = GetTime()
    for _, mod in ipairs(ns.moduleList) do
        if editChanged and mod.MarkDirty then mod.MarkDirty() end
        if mod.OnTick then mod.OnTick(now) end
    end
end

local function SlowTick()
    for _, mod in ipairs(ns.moduleList) do
        if mod.OnSlowTick then mod.OnSlowTick() end
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local OLD_ADDONS = { "PRDVisibility", "XPBarVisibility", "ClassBarsVisibility", "MinimapElementsVisibility" }

local function IsLoaded(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded(name) end
    return IsAddOnLoaded and IsAddOnLoaded(name)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            InitDB()
        elseif ns.db then
            for _, mod in ipairs(ns.moduleList) do
                if mod.OnAddonLoaded then mod.OnAddonLoaded(arg1) end
            end
        end
    elseif event == "PLAYER_LOGIN" then
        if not ns.db then InitDB() end
        for _, mod in ipairs(ns.moduleList) do
            if mod.OnLogin then mod.OnLogin() end
        end
        RegisterSettings()
        C_Timer.NewTicker(ns.TICK, Tick)
        C_Timer.NewTicker(ns.SLOW_TICK, SlowTick)
        ns.Print(L.loaded)
        for _, name in ipairs(OLD_ADDONS) do
            if IsLoaded(name) then ns.Print(string.format(L.oldAddon, name)) end
        end
    end
end)

---------------------------------------------------------------------------
-- Slash commands (English and Spanish)
---------------------------------------------------------------------------
local TAB_ALIASES = {
    prd = "prd", resource = "prd", recursos = "prd",
    xp = "xp", exp = "xp",
    bars = "bars", barras = "bars",
    minimap = "minimap", minimapa = "minimap",
}

local function PrintAllStatus()
    for _, mod in ipairs(ns.moduleList) do
        if mod.db.enabled and mod.PrintStatus then mod.PrintStatus() end
    end
end

-- Handles "cmd arg" for one module: its own commands first, then status.
local function ModuleCommand(mod, cmd, arg)
    if cmd == "" then ns.OpenWindow(mod.key); return end
    if cmd == "status" or cmd == "estado" then
        if mod.PrintStatus then mod.PrintStatus() end
        return
    end
    if mod.Command and mod.Command(cmd, arg) then return end
    ns.Print(L.commands)
end

local function Parse(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$")
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    return cmd:lower(), arg
end

SLASH_UIVISIBILITY1 = "/uiv"
SlashCmdList.UIVISIBILITY = function(msg)
    local cmd, arg = Parse(msg)
    if cmd == "" then
        ns.OpenWindow()
    elseif TAB_ALIASES[cmd] then
        local sub, subArg = Parse(arg)
        ModuleCommand(ns.moduleByKey[TAB_ALIASES[cmd]], sub, subArg)
    elseif cmd == "options" or cmd == "opciones" then
        OpenSettings()
    elseif cmd == "help" or cmd == "ayuda" then
        ns.ShowHelp()
    elseif cmd == "status" or cmd == "estado" then
        PrintAllStatus()
    else
        for _, mod in ipairs(ns.moduleList) do
            if mod.Command and mod.Command(cmd, arg) then return end
        end
        ns.Print(L.commands)
    end
end

-- The old addons' commands still work and go to their module.
local function Alias(slashName, command, moduleKey)
    _G["SLASH_" .. slashName .. "1"] = command
    SlashCmdList[slashName] = function(msg)
        local cmd, arg = Parse(msg)
        if cmd == "options" or cmd == "opciones" then OpenSettings(); return end
        if cmd == "help" or cmd == "ayuda" then ns.ShowHelp(); return end
        ModuleCommand(ns.moduleByKey[moduleKey], cmd, arg)
    end
end
Alias("UIVISIBILITY_PRD", "/prdv", "prd")
Alias("UIVISIBILITY_XP", "/xpbv", "xp")
Alias("UIVISIBILITY_BARS", "/cbv", "bars")
Alias("UIVISIBILITY_MINIMAP", "/mev", "minimap")
