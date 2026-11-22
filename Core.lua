-- UI Visibility: core
-- Shared settings, texts, helpers, options window, help window, update loop
-- and slash commands. Each part of the interface is a module in its own file.

local ADDON_NAME, ns = ...

ns.PREFIX = "|cff33ff99UI Visibility:|r "
ns.ICON = "Interface\\AddOns\\UIVisibility\\Media\\Icon"
ns.TICK = 0.05      -- fast update interval (seconds), shared by all modules
ns.SLOW_TICK = 5    -- slow update interval (seconds)

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
    tab_general = "General",
    generalTitle = "General Options",
    page_bars = "Bars",
    page_frames = "Frames",
    sec_modules = "Modules",
    generalIntro = "Choose when each part of the interface shows. Turn modules on here and press Open to set them up.",
    desc_actionbars = "Hide your action bars, or choose when they show.",
    desc_bars = "Stance, pet, possess and totem bars.",
    desc_xp = "Shows the XP bar on hover and after gaining XP.",
    desc_unitframes = "Player, target, party and other unit frames.",
    desc_prd = "The health and resource bars under your character.",
    desc_interface = "Chat, quest trackers, buffs, bags and menu.",
    desc_minimap = "Texts and buttons around the minimap.",
    desc_names = "Name under the cursor, and names above heads.",
    sec_appearance = "Appearance",
    sec_language = "Language and help",
    sec_profile = "Settings for this character",
    prof_char = "Character: %s",
    prof_accountWide = "Use account-wide settings",
    prof_accountWide_tip = "On: this character shares its settings with every character that has this on. "
        .. "Off: it keeps its own, starting as a copy of the account-wide ones (which stay as they are).",
    prof_copy = "Copy settings from",
    prof_copy_tip = "Replaces this character's settings with a copy of the ones you pick. This character then uses its own settings.",
    prof_choose = "Choose...",
    prof_account = "Account-wide settings",
    prof_noneOther = "No other character has its own settings yet",
    prof_note = "Both reload the interface.",
    prof_toOwn = "Give this character its own settings? It starts with a copy of the account-wide ones. The interface reloads.",
    prof_toAccount = "Use the account-wide settings on this character? Its own settings are kept in case you come back. The interface reloads.",
    prof_copyAsk = "Copy the settings of %s to this character? Its current settings are replaced. The interface reloads.",
    open = "Open",
    fadeSmooth = "Fade smoothness",
    fadeNote = "0 is instant.",
    instant = "Instant",
    shown = "Shown", hidden = "Hidden", hover = "On hover",
    notFound = "not found",
    st_off = "turned off. Turn it on in the General tab (/uiv).",
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
    commands = "commands: /uiv, /uiv prd, /uiv xp, /uiv bars, /uiv actionbars, /uiv unitframes, /uiv interface, /uiv minimap, /uiv names, /uiv groups, /uiv options, /uiv help, /uiv status, /uiv togglenames",
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
    tab_general = "General",
    generalTitle = "Opciones generales",
    page_bars = "Barras",
    page_frames = "Marcos",
    sec_modules = "Módulos",
    generalIntro = "Elige cuándo se ve cada parte de la interfaz. Activa los módulos aquí y pulsa Abrir para configurarlos.",
    desc_actionbars = "Oculta tus barras de acción, o elige cuándo se ven.",
    desc_bars = "Barras de posturas, mascota, posesión y tótems.",
    desc_xp = "Muestra la barra de XP con el mouse y al ganar XP.",
    desc_unitframes = "Marcos del jugador, objetivo, grupo y otros.",
    desc_prd = "Las barras de vida y recurso bajo tu personaje.",
    desc_interface = "Chat, misiones, beneficios, bolsas y menú.",
    desc_minimap = "Textos y botones alrededor del minimapa.",
    desc_names = "Nombre bajo el cursor y nombres sobre la cabeza.",
    sec_appearance = "Apariencia",
    sec_language = "Idioma y ayuda",
    sec_profile = "Configuración de este personaje",
    prof_char = "Personaje: %s",
    prof_accountWide = "Usar la configuración de la cuenta",
    prof_accountWide_tip = "Activado: este personaje comparte su configuración con todos los personajes que lo tengan activado. "
        .. "Desactivado: tiene la suya propia, que empieza como copia de la de la cuenta (que queda igual).",
    prof_copy = "Copiar configuración de",
    prof_copy_tip = "Reemplaza la configuración de este personaje por una copia de la que elijas. El personaje pasa a usar su configuración propia.",
    prof_choose = "Elegir...",
    prof_account = "Configuración de la cuenta",
    prof_noneOther = "Ningún otro personaje tiene configuración propia todavía",
    prof_note = "Ambos recargan la interfaz.",
    prof_toOwn = "¿Dar a este personaje su propia configuración? Empieza con una copia de la de la cuenta. La interfaz se recarga.",
    prof_toAccount = "¿Usar la configuración de la cuenta en este personaje? Su configuración propia se guarda por si vuelves. La interfaz se recarga.",
    prof_copyAsk = "¿Copiar la configuración de %s a este personaje? Su configuración actual se reemplaza. La interfaz se recarga.",
    open = "Abrir",
    fadeSmooth = "Suavidad del fundido",
    fadeNote = "0 es instantáneo.",
    instant = "Instantáneo",
    shown = "Visible", hidden = "Oculta", hover = "Con el mouse",
    notFound = "no encontrado",
    st_off = "desactivado. Actívalo en la pestaña General (/uiv).",
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
    commands = "comandos: /uiv, /uiv prd, /uiv xp, /uiv bars, /uiv actionbars, /uiv unitframes, /uiv interface, /uiv minimap, /uiv names, /uiv grupos, /uiv opciones, /uiv ayuda, /uiv estado, /uiv togglenames",
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

-- Some frames answer with "secret" values that addons can't test (for
-- example parts of the target frame). This tells if a value is one of them.
function ns.IsSecret(v)
    return issecretvalue ~= nil and issecretvalue(v)
end

local function EffectiveScale(obj)
    if obj.GetEffectiveScale then return obj:GetEffectiveScale() end
    local parent = obj:GetParent()
    return parent and parent:GetEffectiveScale() or 1
end

-- True if the cursor is inside the object's rectangle on screen. Calculated
-- directly because the game's MouseIsOver fails in Forever.
function ns.IsCursorOver(obj)
    local visible = obj:IsVisible()
    if ns.IsSecret(visible) or not visible then return false end
    local left, bottom, width, height = obj:GetRect()
    if ns.IsSecret(left) or ns.IsSecret(bottom) or ns.IsSecret(width) or ns.IsSecret(height) then
        return false
    end
    if not left then return false end
    local x, y = GetCursorPosition()
    local scale = EffectiveScale(obj)
    x, y = x / scale, y / scale
    return x >= left and x <= left + width and y >= bottom and y <= bottom + height
end

-- Fade duration in seconds, from the "Fade smoothness" setting (0 to 10):
-- 0 is instant, each step adds 0.1 seconds.
function ns.FadeTime()
    local steps = ns.settings and ns.settings.fadeSmoothness or 2
    return steps * 0.1
end

-- Moves an object's opacity one step toward the target. Returns true while
-- the fade is still in progress.
function ns.Fade(obj, target)
    local current = obj:GetAlpha()
    if ns.IsSecret(current) then
        obj:SetAlpha(target) -- can't read it, so set it directly
        return false
    end
    local diff = target - current
    if math.abs(diff) < 0.001 then return false end
    local fadeTime = ns.FadeTime()
    if fadeTime <= 0 then
        obj:SetAlpha(target)
        return false
    end
    local step = ns.TICK / fadeTime
    if diff > step then diff = step elseif diff < -step then diff = -step end
    obj:SetAlpha(current + diff)
    return true
end

---------------------------------------------------------------------------
-- Option widgets shared by the modules
---------------------------------------------------------------------------
-- Shows an explanation when the mouse is over a label (a FontString).
function ns.AttachTooltip(parent, fontString, title, tip)
    if not tip then return end
    local hover = CreateFrame("Frame", nil, parent)
    hover:SetAllPoints(fontString)
    hover:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 0.82, 0)
        GameTooltip:AddLine(tip, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    hover:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- A checkbox with a label. Optional "opts":
--   x        horizontal position (default 16; use 32 or more to indent an
--            option that depends on the one above, or ~210 for a second column)
--   width    label width, so it doesn't run into a second column
--   tooltip  explanation shown when the mouse is over the option
--   enabledIf function; while it returns false the option is grayed out
function ns.CreateCheck(parent, label, y, getter, setter, opts)
    opts = opts or {}
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", opts.x or 16, y)
    cb:SetSize(26, 26)
    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    text:SetJustifyH("LEFT")
    if opts.width then
        text:SetWidth(opts.width)
        text:SetWordWrap(false)
    end
    text:SetText(label)
    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
    end)
    if opts.tooltip then
        local function show(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 0.82, 0)
            GameTooltip:AddLine(opts.tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end
        cb:SetScript("OnEnter", show)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        -- The label is part of the option too.
        cb:SetHitRectInsets(0, -(opts.width or text:GetStringWidth()) - 4, 0, 0)
    end
    return function()
        cb:SetChecked(getter())
        if opts.enabledIf then
            local on = opts.enabledIf() and true or false
            cb:SetEnabled(on)
            if on then text:SetTextColor(1, 1, 1) else text:SetTextColor(0.5, 0.5, 0.5) end
        end
    end
end

function ns.CreateHeader(parent, text, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", 18, y)
    fs:SetText(text)
end

-- Page header: icon, "UI Visibility" in gold, a dot and the page name in
-- white, over a dark band with a gold line that fades to the right.
-- Takes 44 pixels from the top of "parent".
function ns.CreatePageHeader(parent, pageName)
    local band = parent:CreateTexture(nil, "BACKGROUND")
    band:SetPoint("TOPLEFT", 4, -2)
    band:SetPoint("TOPRIGHT", -4, -2)
    band:SetHeight(36)
    band:SetColorTexture(0, 0, 0, 0.45)

    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("LEFT", band, "LEFT", 10, 0)
    icon:SetTexture(ns.ICON)

    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    title:SetText("UI Visibility")

    local dot = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dot:SetPoint("LEFT", title, "RIGHT", 8, 0)
    dot:SetText("\226\128\162") -- bullet

    local name = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("LEFT", dot, "RIGHT", 8, 0)
    name:SetText(pageName)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", band, "BOTTOMLEFT", 0, 0)
    line:SetPoint("TOPRIGHT", band, "BOTTOMRIGHT", 0, 0)
    line:SetHeight(1)
    line:SetColorTexture(1, 1, 1, 1)
    local ok = pcall(line.SetGradient, line, "HORIZONTAL",
        CreateColor(1, 0.82, 0, 0.9), CreateColor(1, 0.82, 0, 0))
    if not ok then line:SetColorTexture(1, 0.82, 0, 0.5) end
end

-- Title of a module inside a page that holds several modules: bigger than a
-- section title, over a dark band with a gold mark on the left. Takes 40
-- pixels.
function ns.CreateModuleTitle(parent, text, y)
    local band = parent:CreateTexture(nil, "BACKGROUND")
    band:SetPoint("TOPLEFT", 8, y)
    band:SetPoint("RIGHT", parent, "RIGHT", -8, 0)
    band:SetHeight(32)
    band:SetColorTexture(0, 0, 0, 0.35)

    local mark = parent:CreateTexture(nil, "ARTWORK")
    mark:SetPoint("TOPLEFT", band, "TOPLEFT", 0, 0)
    mark:SetPoint("BOTTOMLEFT", band, "BOTTOMLEFT", 0, 0)
    mark:SetWidth(3)
    mark:SetColorTexture(1, 0.82, 0, 0.9)

    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    fs:SetPoint("LEFT", band, "LEFT", 12, 0)
    fs:SetText(text)
end

-- A section title with a thin line under it. Takes about 30 pixels.
function ns.CreateSection(parent, text, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    fs:SetPoint("TOPLEFT", 16, y)
    fs:SetText(text)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.82, 0, 0.25)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", 16, y - 20)
    line:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
end

-- A small gray explanation. Returns its height, so the next option can go
-- right below it however many lines it takes.
function ns.CreateNote(parent, text, y, width)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    fs:SetPoint("TOPLEFT", 18, y)
    fs:SetWidth(width or 380)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    return math.ceil(fs:GetStringHeight())
end

-- Icon of each module, shown in the General tab.
local MODULE_ICONS = {
    actionbars = "Interface\\Icons\\Ability_DualWield",
    bars       = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
    xp         = "Interface\\Icons\\INV_Scroll_03",
    unitframes = "Interface\\Icons\\INV_Misc_GroupNeedMore",
    prd        = "Interface\\Icons\\Spell_Holy_Renew",
    interface  = "Interface\\Icons\\INV_Misc_Bag_08",
    minimap    = "Interface\\Icons\\INV_Misc_Map_01",
    names      = "Interface\\Icons\\Spell_Holy_MindVision",
    groups     = "Interface\\Icons\\INV_Misc_Spyglass_03",
}

-- Description of a module, or nil.
function ns.ModuleDescription(mod)
    local key = "desc_" .. mod.key
    local text = L[key]
    if text ~= key then return text end
end

-- A row for the General tab: icon, name, description, Open button and the
-- checkbox that turns the module on or off. Takes 56 pixels.
local function CreateModuleRow(parent, mod, y, index, onOpen)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
    row:SetPoint("RIGHT", parent, "RIGHT", -8, 0)
    row:SetHeight(52)

    local band = row:CreateTexture(nil, "BACKGROUND")
    band:SetAllPoints()
    band:SetColorTexture(0, 0, 0, index % 2 == 1 and 0.35 or 0.2)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(36, 36)
    icon:SetPoint("LEFT", 8, 0)
    icon:SetTexture(MODULE_ICONS[mod.key] or ns.ICON)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    check:SetSize(26, 26)
    check:SetPoint("RIGHT", -6, 0)
    check:SetScript("OnClick", function(self) mod.SetEnabled(self:GetChecked() and true or false) end)

    local open = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    open:SetSize(76, 22)
    open:SetPoint("RIGHT", check, "LEFT", -6, 0)
    open:SetText(L.open)
    open:SetScript("OnClick", function() onOpen(mod) end)

    local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -1)
    title:SetPoint("RIGHT", open, "LEFT", -8, 0)
    title:SetJustifyH("LEFT")
    title:SetText(L[mod.titleKey])

    local desc = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    desc:SetPoint("RIGHT", open, "LEFT", -8, 0)
    desc:SetJustifyH("LEFT")
    desc:SetTextColor(0.75, 0.75, 0.75)
    desc:SetMaxLines(2)
    desc:SetText(ns.ModuleDescription(mod) or "")

    return function() check:SetChecked(mod.db.enabled) end
end

-- Options shared by the stepper, slider and dropdown:
--   opts.x: where the label starts (indented under the option it depends on).
--   opts.enabledIf: function; while it returns false the control is greyed
--   out and can't be used.
local function LabelColor(fs, on)
    if on then fs:SetTextColor(1, 1, 1) else fs:SetTextColor(0.5, 0.5, 0.5) end
end

local function IsOn(opts)
    return not (opts and opts.enabledIf) or (opts.enabledIf() and true or false)
end

function ns.CreateStepper(parent, label, y, getter, setter, minV, maxV, step, suffix, opts)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", (opts and opts.x) or 20, y)
    text:SetText(label)
    ns.AttachTooltip(parent, text, label, opts and opts.tooltip)

    local value = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("TOPLEFT", 250, y)
    value:SetJustifyH("CENTER")
    value:SetWidth(44)

    -- "suffix" can be text added after the number, or a function that
    -- formats the whole value.
    local minus, plus
    local function Refresh()
        if type(suffix) == "function" then
            value:SetText(suffix(getter()))
        else
            value:SetText(getter() .. suffix)
        end
        local on = IsOn(opts)
        minus:SetEnabled(on)
        plus:SetEnabled(on)
        LabelColor(text, on)
        LabelColor(value, on)
    end

    minus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    minus:SetSize(24, 20)
    minus:SetPoint("RIGHT", value, "LEFT", -2, 0)
    minus:SetText("-")
    minus:SetScript("OnClick", function()
        setter(math.max(minV, getter() - step)); Refresh()
    end)

    plus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    plus:SetSize(24, 20)
    plus:SetPoint("LEFT", value, "RIGHT", 2, 0)
    plus:SetText("+")
    plus:SetScript("OnClick", function()
        setter(math.min(maxV, getter() + step)); Refresh()
    end)
    return Refresh
end

-- A slider from minV to maxV in steps of 1. Uses the game's current slider
-- (MinimalSliderWithSteppersTemplate); if this client doesn't have it,
-- falls back to the - / + stepper. "format" turns a value into its label.
function ns.CreateSlider(parent, label, y, getter, setter, minV, maxV, format, opts)
    local ok, refresh = pcall(function()
        local slider = CreateFrame("Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
        slider:SetPoint("TOPLEFT", 180, y + 6)
        slider:SetWidth(200)
        local formatters = {
            [MinimalSliderWithSteppersMixin.Label.Right] =
                CreateMinimalSliderFormatter(MinimalSliderWithSteppersMixin.Label.Right, format),
        }
        slider:Init(getter(), minV, maxV, maxV - minV, formatters)
        slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
            setter(math.floor(value + 0.5))
        end, slider)

        local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOPLEFT", (opts and opts.x) or 20, y)
        text:SetText(label)
        ns.AttachTooltip(parent, text, label, opts and opts.tooltip)
        return function()
            slider:SetValue(getter())
            local on = IsOn(opts)
            if slider.SetEnabled then pcall(slider.SetEnabled, slider, on) end
            LabelColor(text, on)
        end
    end)
    if ok then return refresh end
    return ns.CreateStepper(parent, label, y, getter, setter, minV, maxV, 1, "", opts)
end

-- A label with a dropdown menu to pick one of a list of values. "values" are
-- keys translated with L. Uses the game's current dropdown
-- (WowStyle1DropdownTemplate), or the older UIDropDownMenu if this client
-- doesn't have it.
local optionDropdownCount = 0

function ns.CreateDropdown(parent, label, y, values, getter, setter, opts)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", (opts and opts.x) or 20, y)
    text:SetText(label)
    ns.AttachTooltip(parent, text, label, opts and opts.tooltip)

    local ok, dropdown = pcall(CreateFrame, "DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    if ok and dropdown and dropdown.SetupMenu then
        dropdown:SetWidth(170)
        dropdown:SetPoint("TOPLEFT", 196, y + 6)
        dropdown:SetupMenu(function(_, root)
            for _, value in ipairs(values) do
                root:CreateRadio(L[value],
                    function() return getter() == value end,
                    function() setter(value) end)
            end
        end)
        return function()
            dropdown:GenerateMenu()
            local on = IsOn(opts)
            dropdown:SetEnabled(on)
            LabelColor(text, on)
        end
    end

    optionDropdownCount = optionDropdownCount + 1
    local legacy = CreateFrame("Frame", "UIVisibilityOptionDropdown" .. optionDropdownCount, parent, "UIDropDownMenuTemplate")
    legacy:SetPoint("TOPLEFT", 180, y + 8)
    UIDropDownMenu_SetWidth(legacy, 160)
    UIDropDownMenu_Initialize(legacy, function()
        for _, value in ipairs(values) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = L[value]
            info.checked = getter() == value
            info.func = function()
                setter(value)
                UIDropDownMenu_SetText(legacy, L[value])
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    return function()
        UIDropDownMenu_SetText(legacy, L[getter()])
        local on = IsOn(opts)
        if on then UIDropDownMenu_EnableDropDown(legacy) else UIDropDownMenu_DisableDropDown(legacy) end
        LabelColor(text, on)
    end
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

-- Settings per character
-- UIVisibilityDB holds everything, account-wide:
--   language, lastTab: always shared.
--   modules, fadeSmoothness: the account-wide settings (as in older versions).
--   chars["Name - Realm"] = { own = true/false, settings = { modules, fadeSmoothness } }:
--     a character with own = true uses its "settings" instead of the account-wide
--     ones. Turning own off keeps them, in case it's turned on again.
-- ns.settings is the table in use (UIVisibilityDB itself, or a character's).
-- Modules read their settings at load, so switching needs a reload.
local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do copy[k] = DeepCopy(v) end
    return copy
end
ns.DeepCopy = DeepCopy

local function CharKey()
    local name = UnitName("player")
    if type(name) ~= "string" or ns.IsSecret(name) or name == "" then return nil end
    local realm = GetRealmName and GetRealmName()
    if type(realm) ~= "string" or ns.IsSecret(realm) or realm == "" then realm = "?" end
    return name .. " - " .. realm
end

local function InitDB()
    UIVisibilityDB = UIVisibilityDB or {}
    local db = UIVisibilityDB
    if db.language == nil then db.language = "en" end
    if db.lastTab == nil then db.lastTab = "general" end
    if db.fadeSmoothness == nil then db.fadeSmoothness = 2 end
    db.modules = db.modules or {}
    db.chars = db.chars or {}

    local settings = db
    ns.charKey = CharKey()
    if ns.charKey then
        local char = db.chars[ns.charKey] or { own = false }
        db.chars[ns.charKey] = char
        if char.own then
            char.settings = char.settings or {}
            settings = char.settings
            if settings.fadeSmoothness == nil then settings.fadeSmoothness = db.fadeSmoothness end
            settings.modules = settings.modules or {}
        end
    end

    for _, mod in ipairs(ns.moduleList) do
        settings.modules[mod.key] = settings.modules[mod.key] or {}
        ApplyDefaults(settings.modules[mod.key], mod.defaults)
        mod.db = settings.modules[mod.key]
    end
    ns.db = db
    ns.settings = settings
    ns.L = ns.LOCALES[db.language] or ns.LOCALES.en
end

-- A copy of some settings ("account" or a character key), ready to become
-- this character's. Modules can fix values that belong to this session
-- (mod.OnCopy, like Names' hidden-names state).
local function CopyOf(source)
    local db = UIVisibilityDB
    local from
    if source == "account" then
        from = { modules = db.modules, fadeSmoothness = db.fadeSmoothness }
    else
        local char = db.chars[source]
        from = char and char.settings
    end
    if not from then return nil end
    local copy = DeepCopy({ modules = from.modules or {}, fadeSmoothness = from.fadeSmoothness })
    for _, mod in ipairs(ns.moduleList) do
        if mod.OnCopy and copy.modules[mod.key] then mod.OnCopy(copy.modules[mod.key], mod.db) end
    end
    return copy
end

-- Characters (other than this one) that have their own settings, sorted.
local function OtherCharacters()
    local list = {}
    for key, char in pairs(UIVisibilityDB.chars or {}) do
        if key ~= ns.charKey and char.own and char.settings then list[#list + 1] = key end
    end
    table.sort(list)
    return list
end

local function UsesOwn()
    local char = ns.charKey and UIVisibilityDB.chars[ns.charKey]
    return char and char.own or false
end

local function ConfirmReload(text, onAccept, onCancel)
    StaticPopupDialogs["UIVISIBILITY_PROFILE"] = {
        text = text,
        button1 = L.reloadNow,
        button2 = CANCEL or L.later,
        OnAccept = onAccept,
        OnCancel = onCancel,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("UIVISIBILITY_PROFILE")
end

local function SetOwnSettings(own, onCancel)
    if not ns.charKey or own == UsesOwn() then return end
    ConfirmReload(own and L.prof_toOwn or L.prof_toAccount, function()
        local char = UIVisibilityDB.chars[ns.charKey]
        if own and not char.settings then char.settings = CopyOf("account") end
        char.own = own
        ReloadUI()
    end, onCancel)
end

local function CopySettingsFrom(source)
    if not ns.charKey then return end
    local name = source == "account" and L.prof_account or source
    ConfirmReload(string.format(L.prof_copyAsk, name), function()
        local copy = CopyOf(source)
        if not copy then return end
        local char = UIVisibilityDB.chars[ns.charKey]
        char.settings = copy
        char.own = true
        ReloadUI()
    end)
end

-- "Copy settings from": a menu of sources, not a choice that stays shown.
local copyDropdownCount = 0
local function CreateCopyDropdown(parent, y)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", 20, y)
    text:SetText(L.prof_copy)
    ns.AttachTooltip(parent, text, L.prof_copy, L.prof_copy_tip)

    local function Sources()
        local list = {}
        if UsesOwn() then list[1] = "account" end
        for _, key in ipairs(OtherCharacters()) do list[#list + 1] = key end
        return list
    end
    local function Name(source) return source == "account" and L.prof_account or source end

    local ok, dropdown = pcall(CreateFrame, "DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    if ok and dropdown and dropdown.SetupMenu then
        dropdown:SetWidth(170)
        dropdown:SetPoint("TOPLEFT", 196, y + 6)
        if dropdown.SetDefaultText then pcall(dropdown.SetDefaultText, dropdown, L.prof_choose) end
        dropdown:SetupMenu(function(_, root)
            local sources = Sources()
            if #sources == 0 then
                root:CreateTitle(L.prof_noneOther)
                return
            end
            for _, source in ipairs(sources) do
                root:CreateButton(Name(source), function() CopySettingsFrom(source) end)
            end
            if #OtherCharacters() == 0 then root:CreateTitle(L.prof_noneOther) end
        end)
        return function()
            dropdown:GenerateMenu()
            if dropdown.Text and not dropdown.SetDefaultText then dropdown.Text:SetText(L.prof_choose) end
            dropdown:SetEnabled(ns.charKey ~= nil)
        end
    end

    copyDropdownCount = copyDropdownCount + 1
    local legacy = CreateFrame("Frame", "UIVisibilityCopyDropdown" .. copyDropdownCount, parent, "UIDropDownMenuTemplate")
    legacy:SetPoint("TOPLEFT", 180, y + 8)
    UIDropDownMenu_SetWidth(legacy, 160)
    UIDropDownMenu_Initialize(legacy, function()
        local sources = Sources()
        for _, source in ipairs(sources) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = Name(source)
            info.notCheckable = true
            info.func = function() CopySettingsFrom(source) end
            UIDropDownMenu_AddButton(info)
        end
        if #OtherCharacters() == 0 then
            local info = UIDropDownMenu_CreateInfo()
            info.text = L.prof_noneOther
            info.notCheckable = true
            info.disabled = true
            UIDropDownMenu_AddButton(info)
        end
    end)
    return function() UIDropDownMenu_SetText(legacy, L.prof_choose) end
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

-- Scrolling area for option pages. Returns the frame to build the options
-- into. Its height is measured from the options it holds (FitContent), so
-- the scroll bar only scrolls as far as needed. Works with the mouse wheel.
local function CreateScrollArea(parent, top)
    local ok, scroll = pcall(CreateFrame, "ScrollFrame", nil, parent, "ScrollFrameTemplate")
    if not ok or not scroll then
        scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    end
    scroll:SetPoint("TOPLEFT", 0, top)
    scroll:SetPoint("BOTTOMRIGHT", -28, 6)
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(400, 1)
    scroll:SetScrollChild(content)
    scroll:HookScript("OnSizeChanged", function(self, width)
        if width and width > 0 then content:SetWidth(width) end
    end)
    return content
end

-- Sets the content's height to reach the lowest option inside it. Options
-- are placed from the top with fixed offsets, so their offsets and heights
-- give the total without waiting for the game to lay them out.
local function FitContent(content)
    local lowest = 0
    local function measure(obj)
        for i = 1, obj:GetNumPoints() do
            local point, relativeTo, _, _, y = obj:GetPoint(i)
            if (relativeTo == content or relativeTo == nil) and point and point:find("^TOP") and y then
                local height = obj.GetStringHeight and obj:GetStringHeight() or obj:GetHeight()
                local bottom = y - (height or 0)
                if bottom < lowest then lowest = bottom end
            end
        end
    end
    for _, child in ipairs({ content:GetChildren() }) do measure(child) end
    for _, region in ipairs({ content:GetRegions() }) do measure(region) end
    content:SetHeight(-lowest + 16)
end

-- General page: modules with an Open button each, fade smoothness,
-- language and help. "openModule" decides where Open takes you.
local function BuildGeneral(parent, y, openModule)
    local refreshers = {}

    y = y - ns.CreateNote(parent, L.generalIntro, y - 2) - 16

    ns.CreateSection(parent, L.sec_modules, y)
    y = y - 32
    for i, mod in ipairs(ns.moduleList) do
        refreshers[#refreshers + 1] = CreateModuleRow(parent, mod, y, i, openModule)
        y = y - 56
    end
    y = y - 12

    ns.CreateSection(parent, L.sec_appearance, y)
    y = y - 34
    refreshers[#refreshers + 1] = ns.CreateSlider(parent, L.fadeSmooth, y,
        function() return ns.settings.fadeSmoothness end,
        function(v) ns.settings.fadeSmoothness = v end,
        0, 10,
        function(v)
            v = math.floor(v + 0.5)
            if v == 0 then return L.instant end
            return tostring(v)
        end,
        { tooltip = L.fadeNote })
    y = y - 40

    -- Settings for this character
    ns.CreateSection(parent, L.sec_profile, y)
    y = y - 30
    local who = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    who:SetPoint("TOPLEFT", 20, y)
    who:SetText(string.format(L.prof_char, ns.charKey or "?"))
    y = y - 22
    local accountCheck
    accountCheck = ns.CreateCheck(parent, L.prof_accountWide, y,
        function() return not UsesOwn() end,
        function(v)
            SetOwnSettings(not v, function() accountCheck() end)
            accountCheck()
        end,
        { tooltip = L.prof_accountWide_tip, width = 360, enabledIf = function() return ns.charKey ~= nil end })
    refreshers[#refreshers + 1] = accountCheck
    y = y - 32
    refreshers[#refreshers + 1] = CreateCopyDropdown(parent, y)
    y = y - 30
    y = y - ns.CreateNote(parent, L.prof_note, y) - 16

    ns.CreateSection(parent, L.sec_language, y)
    y = y - 42
    CreateBottomButtons(parent, "TOPLEFT", 20, y)
    return function() for _, r in ipairs(refreshers) do r() end end
end

---------------------------------------------------------------------------
-- Pages
---------------------------------------------------------------------------
-- Modules are grouped into pages by where they are on screen. A page with
-- several modules shows them one under the other, each with its own title
-- and Enabled checkbox. The modules themselves stay separate, so their
-- settings and commands don't change. A module not listed here gets a page
-- of its own.
local PAGE_LAYOUT = {
    { key = "pg_bars",      titleKey = "page_bars",   modules = { "actionbars", "bars", "xp" } },
    { key = "pg_frames",    titleKey = "page_frames", modules = { "unitframes", "prd" } },
    { key = "pg_interface", modules = { "interface" } },
    { key = "pg_minimap",   modules = { "minimap" } },
    { key = "pg_names",     modules = { "names" } },
}

local pages, pageByKey, pageOfModule

local function GetPages()
    if pages then return pages end
    pages, pageByKey, pageOfModule = {}, {}, {}
    local used = {}
    local function addPage(page)
        local mods = {}
        for _, key in ipairs(page.modules) do
            local mod = ns.moduleByKey[key]
            if mod then mods[#mods + 1] = mod; used[key] = true end
        end
        if #mods == 0 then return end
        local entry = { key = page.key, mods = mods }
        if page.titleKey and #mods > 1 then
            entry.title, entry.tab = L[page.titleKey], L[page.titleKey]
        else
            entry.title, entry.tab = L[mods[1].titleKey], L[mods[1].tabKey]
        end
        pages[#pages + 1] = entry
        pageByKey[entry.key] = entry
        for _, mod in ipairs(mods) do pageOfModule[mod.key] = entry end
    end
    for _, page in ipairs(PAGE_LAYOUT) do addPage(page) end
    for _, mod in ipairs(ns.moduleList) do
        if not used[mod.key] then addPage({ key = "pg_" .. mod.key, modules = { mod.key } }) end
    end
    return pages
end

-- Turns a module key or a page key into a page key ("general" stays).
local function PageKeyFor(key)
    GetPages()
    if key == "general" or pageByKey[key] then return key end
    if pageOfModule[key] then return pageOfModule[key].key end
    return "general"
end

-- Builds a page's options into "parent". Returns a refresh function.
local function BuildPage(page, parent, y)
    if #page.mods == 1 then
        local mod = page.mods[1]
        local desc = ns.ModuleDescription(mod)
        if desc then y = y - ns.CreateNote(parent, desc, y - 2) - 14 end
        return mod.BuildOptions(parent, y)
    end
    local refreshers, blocks = {}, {}
    for i, mod in ipairs(page.mods) do
        local block = CreateFrame("Frame", nil, parent)
        block:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
        block:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
        block:SetHeight(1)
        ns.CreateModuleTitle(block, L[mod.titleKey], -2)
        local top = -44
        local desc = ns.ModuleDescription(mod)
        if desc then top = top - ns.CreateNote(block, desc, top) - 12 end
        refreshers[#refreshers + 1] = mod.BuildOptions(block, top)
        FitContent(block)
        y = y - block:GetHeight() - 20
        blocks[i] = block
    end
    return function()
        for _, r in ipairs(refreshers) do r() end
        for _, block in ipairs(blocks) do FitContent(block) end
    end
end

---------------------------------------------------------------------------
-- Floating options window with one tab per page (/uiv)
---------------------------------------------------------------------------
local window
local tabs, panes, paneRefresh = {}, {}, {}
local WINDOW_WIDTH = 460
local TABS_PER_ROW = 4
local paneTop = -92 -- set in CreateWindow from the number of tab rows

local SelectTab

local function BuildPane(key, parent)
    if key == "general" then
        return BuildGeneral(parent, -4, function(mod) SelectTab(mod.key) end)
    end
    return BuildPage(pageByKey[key], parent, -4)
end

function SelectTab(key)
    key = PageKeyFor(key)
    ns.db.lastTab = key
    for k, button in pairs(tabs) do
        if k == key then button:LockHighlight() else button:UnlockHighlight() end
    end
    for k, pane in pairs(panes) do pane:SetShown(k == key) end
    if not panes[key] then
        local pane = CreateFrame("Frame", nil, window)
        pane:SetPoint("TOPLEFT", 0, paneTop)
        pane:SetPoint("BOTTOMRIGHT", 0, 8)
        local pageName = key == "general" and L.generalTitle or pageByKey[key].title
        ns.CreatePageHeader(pane, pageName)
        local content = CreateScrollArea(pane, -46)
        local refresh = BuildPane(key, content)
        FitContent(content)
        paneRefresh[key] = function() refresh(); FitContent(content) end
        pane:SetScript("OnShow", function() paneRefresh[key]() end)
        panes[key] = pane
    end
    paneRefresh[key]()
end

local function CreateWindow()
    window = CreateFrame("Frame", "UIVisibilityWindow", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(WINDOW_WIDTH, 560)
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

    -- Tabs: General first, then one per page, in rows of four.
    local keys = { { key = "general", label = L.tab_general } }
    for _, page in ipairs(GetPages()) do
        keys[#keys + 1] = { key = page.key, label = page.tab }
    end
    local rows = math.ceil(#keys / TABS_PER_ROW)
    paneTop = -36 - rows * 28
    window:SetHeight(580 + rows * 28)
    local width = (WINDOW_WIDTH - 24 - (TABS_PER_ROW - 1) * 4) / TABS_PER_ROW
    for i, item in ipairs(keys) do
        local row = math.floor((i - 1) / TABS_PER_ROW)
        local col = (i - 1) % TABS_PER_ROW
        local button = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
        button:SetSize(width, 24)
        button:SetPoint("TOPLEFT", 12 + col * (width + 4), -30 - row * 28)
        button:SetText(item.label)
        button:SetScript("OnClick", function() SelectTab(item.key) end)
        tabs[item.key] = button
    end
end

-- Opens the window on a page. "key" can be a page, a module or "general".
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
    ns.CreatePageHeader(main, L.generalTitle)

    ns.settingsCategory = Settings.RegisterCanvasLayoutCategory(main, "UI Visibility")

    -- One sub-page per page of the window.
    local categoryOfPage = {}
    if Settings.RegisterCanvasLayoutSubcategory then
        for _, entry in ipairs(GetPages()) do
            local page = CreateFrame("Frame")
            page:Hide()
            ns.CreatePageHeader(page, entry.title)
            local content = CreateScrollArea(page, -46)
            local refresh = BuildPage(entry, content, -8)
            page:SetScript("OnShow", function() refresh(); FitContent(content) end)
            categoryOfPage[entry.key] = Settings.RegisterCanvasLayoutSubcategory(ns.settingsCategory, page, entry.title)
        end
    end

    -- "Open" goes to the module's page, or to its tab in the window if
    -- sub-pages aren't available.
    local mainContent = CreateScrollArea(main, -46)
    local mainRefresh = BuildGeneral(mainContent, -8, function(mod)
        local category = categoryOfPage[PageKeyFor(mod.key)]
        if category and Settings.OpenToCategory then
            local ok = pcall(Settings.OpenToCategory, category:GetID())
            if ok then return end
        end
        ns.OpenWindow(mod.key)
    end)
    main:SetScript("OnShow", function() mainRefresh(); FitContent(mainContent) end)

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
    actionbars = "actionbars", ab = "actionbars",
    unitframes = "unitframes", frames = "unitframes", uf = "unitframes",
    interface = "interface", interfaz = "interface",
    names = "names", nombres = "names",
    groups = "groups", grupos = "groups",
    general = "general",
}

-- A turned off module says so, instead of listing settings that don't apply.
local function PrintModuleStatus(mod)
    if not mod.db.enabled then
        ns.Print(L[mod.titleKey] .. ": " .. L.st_off)
    elseif mod.PrintStatus then
        mod.PrintStatus()
    end
end

local function PrintAllStatus()
    for _, mod in ipairs(ns.moduleList) do PrintModuleStatus(mod) end
end

-- Handles "cmd arg" for one module: its own commands first, then status.
local function ModuleCommand(mod, cmd, arg)
    if cmd == "" then ns.OpenWindow(mod.key); return end
    if cmd == "status" or cmd == "estado" then
        PrintModuleStatus(mod)
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
    elseif TAB_ALIASES[cmd] == "general" then
        ns.OpenWindow("general")
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