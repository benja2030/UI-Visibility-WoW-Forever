-- UI Visibility: names module
-- Helps read the name of the character under the mouse, at any distance.
--
-- The names above characters' heads are drawn by the game engine, and addons
-- can't know where a character's head is on screen. But while you hover a
-- character, the cursor is on top of it, and addons do know where the cursor
-- is. So this module offers two things:
--   * Name at the cursor: a big copy of the hovered character's name, in the
--     game's name colors, follows the cursor while you hover them. Their
--     level can show after the name, colored by difficulty. A quest
--     mark can show next to it when the character is part of one of your
--     active quests.
--   * Tooltip at the cursor: the tooltip shows up next to the cursor instead
--     of in the corner, optionally bigger.
--
-- It also offers the game's own settings for the names above heads, by
-- category (players, NPCs, pets, critters...), and a way to hide them all and
-- bring them back exactly as they were (/uiv togglenames).
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
    nm_title = "Character names",

    nm_secName = "Name at the cursor",
    nm_withName = "Next to the name",
    nm_nameNote = "The name of the player or NPC you hover, in big letters next to the cursor.",
    nm_quickNote = "Hides every name above heads at once, and brings them back as they were.",
    nm_tooltipSecNote = "The game's box with information when you hover something.",
    nm_cursorName = "Show name",
    nm_cursorName_tip = "Shows the hovered character's name in big letters next to the cursor.",
    nm_size = "Size",
    nm_position = "Position",
    above = "Above the cursor", right = "Right of the cursor", below = "Below the cursor",
    nm_delay = "Delay",
    nm_showLevel = "Level",
    nm_showLevel_tip = "Shows the level after the name, like (32). Elites get a +, and (??) means too high to see.",
    nm_levelColor = "Difficulty colors",
    nm_levelColor_tip = "Colors the level by how hard the character is for you. Off: the level uses the name's color.",
    nm_npcLevel = "Show on friendly NPCs",
    nm_recovered = "Names were hidden when the game closed. They're shown again.",
    nm_npcLevel_tip = "Off: friendly NPCs (vendors, trainers, guards...) show their name without the level. Players and enemies keep it.",
    nm_npcTitle = "Title of friendly NPCs",
    nm_npcTitle_tip = "Shows the title of friendly NPCs under their name, like <Food & Drink Vendor>. It's read from the game's tooltip data.",
    nm_questMark = "Quest mark",
    nm_questMark_tip = "Shows a ! before the name when the character is part of one of your active quests.",

    nm_secWho = "Show the name for",
    nm_secObjects = "Objects",
    nm_objectsNote = "Things in the world that aren't characters.",
    nm_objHerbs = "Herbs",
    nm_objHerbs_tip = "Plants you gather with Herbalism.",
    nm_objOre = "Mining nodes",
    nm_objOre_tip = "Veins and deposits you gather with Mining.",
    nm_objOther = "Other objects",
    nm_objOther_tip = "Chests, fishing pools, mailboxes, doors and anything else in the world with a tooltip.",
    nm_alliedPlayers = "Allied players",
    nm_enemyPlayers = "Enemy players",
    nm_enemyPlayers_tip = "Players of the other faction, flagged for PvP or not.",
    nm_friendlyNpcs = "Friendly NPCs",
    nm_friendlyNpcs_tip = "NPCs you can't attack, including neutral ones (yellow names).",
    nm_hostileNpcs = "Hostile NPCs",
    nm_hostileNpcs_tip = "NPCs you can attack.",

    nm_secHide = "Hide the name when",
    nm_hideCombat = "In combat",
    nm_hideInstances = "In an instance",
    nm_hideInstances_tip = "Dungeons, raids and battlegrounds.",
    nm_skipDead = "Dead",
    nm_skipDead_tip = "Corpses of NPCs and dead players.",
    nm_skipPlates = "Has a nameplate",
    nm_skipPlates_tip = "The character is close enough to show its nameplate, so you can already read its name.",
    nm_worldOnly = "Over the interface",
    nm_worldOnly_tip = "The mouse is over an interface frame (like the party or target frame) instead of the world.",

    nm_secWorld = "Names above heads",
    nm_worldNote = "The game's own settings. Hover each one for details.",
    nm_wAlliedPlayers = "Allied players",
    nm_wEnemyPlayers = "Enemy players",
    nm_wHostileNpcs = "Hostile NPCs",
    nm_wHostileNpcs_tip = "Monsters and other NPCs you can attack.",
    nm_wInteractiveNpcs = "Interactive NPCs",
    nm_wInteractiveNpcs_tip = "Vendors, quest givers and other NPCs you can talk to.",
    nm_wSpecialNpcs = "Special NPCs",
    nm_wSpecialNpcs_tip = "Special friendly NPCs the game always labels.",
    nm_wAllNpcs = "All NPCs",
    nm_wAllNpcs_tip = "Every NPC, including corpses. Off by default in the game; with it off, the NPC categories above still show.",
    nm_wPets = "Pets",
    nm_wPets_tip = "Pets of allies and enemies.",
    nm_wMinions = "Guardians and minions",
    nm_wMinions_tip = "Summoned guardians and minions of allies and enemies.",
    nm_wTotems = "Totems",
    nm_wTotems_tip = "Totems of allies and enemies.",
    nm_wCritters = "Critters",
    nm_wCritters_tip = "Non-combat creatures, like rabbits and squirrels.",
    nm_wOwn = "Your own name",
    nm_wWeak = "Weak enemies",
    nm_wWeak_tip = "The weakest enemies of big groups. Off hides their names even when hostile NPC names are on.",
    nm_wGuild = "Guild names",
    nm_wGuild_tip = "The guild name under each player's name.",
    nm_wTitles = "Titles",
    nm_wTitles_tip = "Titles shown with players' names.",
    nm_hideAll = "Hide all names",
    nm_showAgain = "Show names again",
    nm_hiddenNote = "Names are hidden. Show them again to change these settings.",
    nm_toggleNote = "Tip: /uiv togglenames does the same in a macro.",
    nm_toggledOff = "names above heads hidden. Use /uiv togglenames to bring them back.",
    nm_toggledOn = "names above heads shown again.",
    nm_secQuick = "Quick toggle",
    nm_showButton = "Show the button",
    nm_secButton = "Button on screen",
    nm_showButton_tip = "Shows a small button that hides or shows all names above heads with one click.",
    nm_buttonMode = "Button mode",
    nm_buttonStyle = "Button icon",
    nm_quickTarget = "Hides",
    nm_quickTarget_tip = "Names and interface also hides the whole interface, like Alt+Z. The button on screen stays visible so you can bring everything back. It can't hide or show the interface during combat.",
    target_names = "Names only",
    target_all = "Names and interface",
    nm_secAuto = "Hide automatically",
    nm_autoNote = "Hides the same as the quick toggle, and brings it back when the reason ends.",
    nm_autoAfk = "While you're away",
    nm_autoAfk_tip = "Hides when you go <Away>, and shows again when you come back.",
    nm_autoIdle = "After time out of combat",
    nm_autoIdle_tip = "Hides after you've been out of combat for the time below, and shows again when combat starts.",
    nm_autoIdleTime = "Time",
    nm_autoStill = "Only while standing still",
    nm_autoStill_tip = "The time only counts while you don't move your character or the mouse. Moving your character shows everything again. Off: names hide even while you walk around.",
    nm_autoMouse = "Moving the mouse shows it again",
    nm_autoMouse_tip = "On: once hidden, moving the mouse brings everything back, like a screensaver. Off: the mouse only stops the count before hiding, and everything stays hidden until you move your character, a fight starts or you use the button.",
    nm_combatBlocked = "the interface can't be hidden or shown during combat. Try again after the fight, or press Alt+Z.",
    style_eye = "Simple eye",
    style_spell = "Game icon",
    nm_buttonIdle = "Opacity when not hovered",
    nm_buttonIdle_tip = "In On hover mode, the button's opacity while the mouse isn't over it. 0% makes it invisible until you hover where it is.",
    nm_buttonSize = "Button size",
    nm_resetPos = "Reset position",
    nm_moveNote = "Shift+drag the button to move it.",
    nm_btnShown = "Names are shown. Click to hide them all.",
    nm_btnHidden = "Names are hidden. Click to show them again.",
    nm_btnMove = "Shift+drag to move.",
    nm_secTooltip = "Tooltip",
    nm_tooltipCursor = "Next to the cursor",
    nm_tooltipCursor_tip = "Shows the tooltip next to the cursor instead of in the corner of the screen.",
    nm_tooltipScale = "Size",
    nm_tooltipDelay = "Delay",
    nm_tooltipNote = "The delay only applies to things in the world, not to buttons or windows.",

    nm_note = "Addons can't know where a head is on screen, so the name follows the cursor.",
    nm_st_disabled = "module disabled",
    nm_st_showing = "showing %s at the cursor",
    nm_st_idle = "waiting for the mouse",
})
ns.AddLocale("es", {
    tab_names = "Nombres",
    nm_title = "Nombres de personajes",

    nm_secName = "Nombre junto al cursor",
    nm_nameNote = "El nombre del jugador o PNJ que apuntas, en grande junto al cursor.",
    nm_quickNote = "Oculta todos los nombres sobre la cabeza a la vez, y los devuelve como estaban.",
    nm_tooltipSecNote = "El recuadro del juego con información al pasar el mouse sobre algo.",
    nm_cursorName = "Mostrar nombre",
    nm_cursorName_tip = "Muestra el nombre del personaje apuntado en letras grandes junto al cursor.",
    nm_size = "Tamaño",
    nm_position = "Posición",
    above = "Sobre el cursor", right = "A la derecha", below = "Bajo el cursor",
    nm_delay = "Retraso",
    nm_showLevel = "Nivel",
    nm_showLevel_tip = "Muestra el nivel después del nombre, como (32). Los élites llevan un +, y (??) significa que es demasiado alto para verlo.",
    nm_levelColor = "Colores de dificultad",
    nm_levelColor_tip = "Colorea el nivel según qué tan difícil es el personaje para ti. Desactivado: el nivel usa el color del nombre.",
    nm_npcLevel = "Mostrar en PNJ amistosos",
    nm_recovered = "Los nombres estaban ocultos cuando se cerró el juego. Se muestran de nuevo.",
    nm_npcLevel_tip = "Desactivado: los PNJ amistosos (vendedores, instructores, guardias...) muestran su nombre sin el nivel. Los jugadores y enemigos lo mantienen.",
    nm_npcTitle = "Título de PNJ amistosos",
    nm_npcTitle_tip = "Muestra el título de los PNJ amistosos bajo su nombre, como <Vendedor de comida y bebida>. Se lee de los datos del tooltip del juego.",
    nm_questMark = "Marca de misión",
    nm_questMark_tip = "Muestra un ! antes del nombre cuando el personaje es parte de una de tus misiones activas.",

    nm_secWho = "Mostrar el nombre para",
    nm_secObjects = "Objetos",
    nm_objectsNote = "Cosas del mundo que no son personajes.",
    nm_objHerbs = "Hierbas",
    nm_objHerbs_tip = "Plantas que se recogen con Herboristería.",
    nm_objOre = "Vetas de mineral",
    nm_objOre_tip = "Vetas y depósitos que se recogen con Minería.",
    nm_objOther = "Otros objetos",
    nm_objOther_tip = "Cofres, bancos de peces, buzones, puertas y cualquier otra cosa del mundo con tooltip.",
    nm_alliedPlayers = "Jugadores aliados",
    nm_enemyPlayers = "Jugadores enemigos",
    nm_enemyPlayers_tip = "Jugadores de la otra facción, con o sin JcJ activado.",
    nm_friendlyNpcs = "PNJ amistosos",
    nm_friendlyNpcs_tip = "PNJ que no puedes atacar, incluidos los neutrales (nombres amarillos).",
    nm_hostileNpcs = "PNJ hostiles",
    nm_hostileNpcs_tip = "PNJ que puedes atacar.",

    nm_secHide = "Ocultar el nombre cuando",
    nm_hideCombat = "Estás en combate",
    nm_hideInstances = "Estás en instancia",
    nm_hideInstances_tip = "Mazmorras, bandas y campos de batalla.",
    nm_skipDead = "Está muerto",
    nm_skipDead_tip = "Cadáveres de PNJ y jugadores muertos.",
    nm_skipPlates = "Tiene placa",
    nm_skipPlates_tip = "El personaje está lo bastante cerca para mostrar su placa, así que ya puedes leer su nombre.",
    nm_worldOnly = "Sobre la interfaz",
    nm_worldOnly_tip = "El mouse está sobre un marco de la interfaz (como el del grupo o el del objetivo) en vez del mundo.",

    nm_secWorld = "Nombres sobre la cabeza",
    nm_worldNote = "Ajustes del propio juego. Pasa el mouse sobre cada uno para ver el detalle.",
    nm_wAlliedPlayers = "Jugadores aliados",
    nm_wEnemyPlayers = "Jugadores enemigos",
    nm_wHostileNpcs = "PNJ hostiles",
    nm_wHostileNpcs_tip = "Monstruos y otros PNJ que puedes atacar.",
    nm_wInteractiveNpcs = "PNJ interactivos",
    nm_wInteractiveNpcs_tip = "Vendedores, PNJ de misiones y otros PNJ con los que puedes hablar.",
    nm_wSpecialNpcs = "PNJ especiales",
    nm_wSpecialNpcs_tip = "PNJ amistosos especiales que el juego siempre etiqueta.",
    nm_wAllNpcs = "Todos los PNJ",
    nm_wAllNpcs_tip = "Todos los PNJ, incluidos los cadáveres. Viene desactivado en el juego; aun así, las categorías de PNJ de arriba se siguen mostrando.",
    nm_wPets = "Mascotas",
    nm_wPets_tip = "Mascotas de aliados y enemigos.",
    nm_wMinions = "Guardianes y esbirros",
    nm_wMinions_tip = "Guardianes y esbirros invocados por aliados y enemigos.",
    nm_wTotems = "Tótems",
    nm_wTotems_tip = "Tótems de aliados y enemigos.",
    nm_wCritters = "Criaturas",
    nm_wCritters_tip = "Criaturas no combatientes, como conejos y ardillas.",
    nm_wOwn = "Tu propio nombre",
    nm_wWeak = "Enemigos menores",
    nm_wWeak_tip = "Los enemigos más débiles de los grupos grandes. Desactivado oculta sus nombres aunque los de PNJ hostiles estén activados.",
    nm_wGuild = "Hermandad",
    nm_wGuild_tip = "El nombre de la hermandad bajo el nombre de cada jugador.",
    nm_wTitles = "Títulos",
    nm_wTitles_tip = "Los títulos que se muestran con el nombre de los jugadores.",
    nm_hideAll = "Ocultar todos los nombres",
    nm_showAgain = "Mostrar los nombres otra vez",
    nm_hiddenNote = "Los nombres están ocultos. Muéstralos otra vez para cambiar estos ajustes.",
    nm_toggleNote = "Consejo: /uiv togglenames hace lo mismo en una macro.",
    nm_toggledOff = "nombres sobre la cabeza ocultos. Usa /uiv togglenames para volver a mostrarlos.",
    nm_toggledOn = "nombres sobre la cabeza visibles otra vez.",
    nm_secQuick = "Alternar rápido",
    nm_withName = "Junto al nombre",
    nm_showButton = "Mostrar el botón",
    nm_secButton = "Botón en pantalla",
    nm_showButton_tip = "Muestra un botón pequeño que oculta o muestra todos los nombres sobre la cabeza con un clic.",
    nm_buttonMode = "Modo del botón",
    nm_buttonStyle = "Ícono del botón",
    nm_quickTarget = "Oculta",
    nm_quickTarget_tip = "Nombres e interfaz también oculta toda la interfaz, como Alt+Z. El botón en pantalla sigue visible para que puedas volver a mostrar todo. No puede ocultar ni mostrar la interfaz durante el combate.",
    target_names = "Solo nombres",
    target_all = "Nombres e interfaz",
    nm_secAuto = "Ocultar automáticamente",
    nm_autoNote = "Oculta lo mismo que el alternar rápido, y lo devuelve cuando la razón termina.",
    nm_autoAfk = "Mientras estás ausente",
    nm_autoAfk_tip = "Oculta cuando quedas <Ausente>, y muestra otra vez cuando vuelves.",
    nm_autoIdle = "Tras un tiempo fuera de combate",
    nm_autoIdle_tip = "Oculta después de estar fuera de combate el tiempo de abajo, y muestra otra vez cuando empieza un combate.",
    nm_autoIdleTime = "Tiempo",
    nm_autoStill = "Solo si estás quieto",
    nm_autoStill_tip = "El tiempo solo cuenta mientras no mueves a tu personaje ni el mouse. Mover a tu personaje vuelve a mostrar todo. Desactivado: los nombres se ocultan aunque estés caminando.",
    nm_autoMouse = "Mover el mouse lo vuelve a mostrar",
    nm_autoMouse_tip = "Activado: una vez oculto, mover el mouse vuelve a mostrar todo, como un protector de pantalla. Desactivado: el mouse solo detiene el contador antes de ocultar, y todo sigue oculto hasta que mueves a tu personaje, empieza un combate o usas el botón.",
    nm_combatBlocked = "la interfaz no se puede ocultar ni mostrar en combate. Inténtalo después de la pelea, o presiona Alt+Z.",
    style_eye = "Ojo simple",
    style_spell = "Ícono del juego",
    nm_buttonIdle = "Opacidad sin mouse",
    nm_buttonIdle_tip = "En modo Con el mouse, la opacidad del botón mientras el mouse no está encima. 0% lo vuelve invisible hasta que pasas el mouse por donde está.",
    nm_buttonSize = "Tamaño del botón",
    nm_resetPos = "Reiniciar posición",
    nm_moveNote = "Mantén Shift y arrastra el botón para moverlo.",
    nm_btnShown = "Los nombres están visibles. Haz clic para ocultarlos todos.",
    nm_btnHidden = "Los nombres están ocultos. Haz clic para mostrarlos otra vez.",
    nm_btnMove = "Shift+arrastrar para mover.",
    nm_secTooltip = "Tooltip",
    nm_tooltipCursor = "Junto al cursor",
    nm_tooltipCursor_tip = "Muestra el tooltip junto al cursor en vez de en la esquina de la pantalla.",
    nm_tooltipScale = "Tamaño",
    nm_tooltipDelay = "Retraso",
    nm_tooltipNote = "El retraso solo aplica a cosas del mundo, no a botones ni ventanas.",

    nm_note = "Los addons no pueden saber dónde está una cabeza en pantalla, así que el nombre sigue al cursor.",
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
        questMark = true,
        showLevel = true,
        levelColor = true,  -- false: the level uses the name's color
        npcLevel = true,    -- false: friendly NPCs show no level
        npcTitle = false,   -- title of friendly NPCs under the name
        skipDead = true,
        alliedPlayers = true,
        enemyPlayers = true,
        friendlyNpcs = true,
        hostileNpcs = true,
        objHerbs = true,
        objOre = true,
        objOther = false,
        worldOnly = true,
        delay = 0,          -- tenths of a second before the name shows
        hideCombat = false,
        hideInstances = false,
        tooltipCursor = false,
        tooltipScale = 100,
        tooltipDelay = 0,
        showButton = false,
        buttonMode = "shown",   -- "shown" or "hover"
        buttonStyle = "style_eye", -- "style_eye" (drawn eye) or "style_spell" (game icon)
        quickTarget = "target_names", -- "target_names" or "target_all" (names and interface)
        autoAfk = false,
        autoIdle = false,
        autoIdleTime = 30,  -- seconds out of combat before hiding
        autoStill = true,   -- the time only counts while standing still
        autoMouseShows = false, -- moving the mouse undoes an "idle" hide
        autoReason = nil,   -- "afk" or "idle" while hidden automatically
        buttonIdleAlpha = 30,   -- % while not hovered, in "hover" mode
        buttonSize = 32,
        buttonPoint = nil,      -- saved position   -- tenths of a second before world tooltips show
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

-- True if the hovered character is part of one of your active quests (a
-- quest target, or someone you must talk to or kill). Uses the game's quest
-- check, or the quest lines of its tooltip data if that check isn't there.
local function IsQuestRelated()
    if C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest then
        local ok, related = pcall(C_QuestLog.UnitIsRelatedToActiveQuest, "mouseover")
        if ok and not ns.IsSecret(related) then return related and true or false end
    end
    if C_TooltipInfo and C_TooltipInfo.GetUnit and Enum and Enum.TooltipDataLineType then
        local types = Enum.TooltipDataLineType
        local ok, data = pcall(C_TooltipInfo.GetUnit, "mouseover")
        if ok and data and data.lines then
            for _, line in ipairs(data.lines) do
                local kind = line.type
                if kind and not ns.IsSecret(kind) and (kind == types.QuestObjective
                    or kind == types.QuestTitle or kind == types.QuestPlayer) then
                    return true
                end
            end
        end
    end
    return false
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
    if db.skipDead then
        local dead = UnitIsDead("mouseover")
        if not ns.IsSecret(dead) and dead then return false end
    end
    local isPlayer = UnitIsPlayer("mouseover")
    if ns.IsSecret(isPlayer) then
        return db.alliedPlayers or db.enemyPlayers or db.friendlyNpcs or db.hostileNpcs
    end

    if isPlayer then
        -- Players: enemy means the other faction, flagged for PvP or not.
        local mine = UnitFactionGroup("player")
        local theirs = UnitFactionGroup("mouseover")
        local enemy
        if ns.IsSecret(mine) or ns.IsSecret(theirs) or not mine or not theirs then
            enemy = UnitIsEnemy("player", "mouseover")
            if ns.IsSecret(enemy) then return db.alliedPlayers or db.enemyPlayers end
        else
            enemy = mine ~= theirs
        end
        if enemy then return db.enemyPlayers end
        return db.alliedPlayers
    end

    -- NPCs: hostile means you can attack it.
    local canAttack = UnitCanAttack("player", "mouseover")
    if ns.IsSecret(canAttack) then return db.friendlyNpcs or db.hostileNpcs end
    if canAttack then return db.hostileNpcs end
    return db.friendlyNpcs
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

-- Title of friendly NPCs (<Food & Drink Vendor>), under the name.
local title = label:CreateFontString(nil, "OVERLAY")
title:Hide()

-- Yellow "!" quest mark, to the left of the name.
local mark = label:CreateTexture(nil, "OVERLAY")
if not (mark.SetAtlas and pcall(mark.SetAtlas, mark, "QuestNormal")) then
    mark:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
end
mark:SetPoint("RIGHT", text, "LEFT", -2, 0)
mark:Hide()

local OFFSETS = {
    above = { "BOTTOM", 0, 24 },
    right = { "LEFT", 28, 0 },
    below = { "TOP", 0, -32 },
}

-- The title goes under the name. Above the cursor, the pair moves up so the
-- title doesn't cover the cursor.
local function PlaceText()
    local position = mod.db.position
    local o = OFFSETS[position] or OFFSETS.above
    text:ClearAllPoints()
    title:ClearAllPoints()
    if title:IsShown() and position ~= "below" and position ~= "right" then
        title:SetPoint("BOTTOM", label, "CENTER", o[2], o[3])
        text:SetPoint("BOTTOM", title, "TOP", 0, 1)
    else
        text:SetPoint(o[1], label, "CENTER", o[2], o[3])
        if position == "right" then
            title:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -1)
        else
            title:SetPoint("TOP", text, "BOTTOM", 0, -1)
        end
    end
end

local function ApplyFont()
    local font = UNIT_NAME_FONT or STANDARD_TEXT_FONT
    if not text:SetFont(font, mod.db.size, "OUTLINE") then
        text:SetFont(STANDARD_TEXT_FONT, mod.db.size, "OUTLINE")
    end
    text:SetShadowOffset(1, -1)
    text:SetShadowColor(0, 0, 0, 1)
    local titleSize = math.max(9, math.floor(mod.db.size * 0.75 + 0.5))
    if not title:SetFont(font, titleSize, "OUTLINE") then
        title:SetFont(STANDARD_TEXT_FONT, titleSize, "OUTLINE")
    end
    title:SetShadowOffset(1, -1)
    title:SetShadowColor(0, 0, 0, 1)
    mark:SetSize(mod.db.size, mod.db.size)
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
-- Level text like the game shows it: "(32)", "(32+)" for elites and "(??)"
-- when it's too high to see. Colored by how hard it is for you, or left in
-- the name's color if that option is off.
local function LevelText()
    local level = UnitLevel("mouseover")
    if ns.IsSecret(level) or not level then return nil end
    local label = level > 0 and tostring(level) or "??"
    local classification = UnitClassification("mouseover")
    if not ns.IsSecret(classification)
        and (classification == "elite" or classification == "rareelite" or classification == "worldboss") then
        label = label .. "+"
    end
    if not mod.db.levelColor then return "(" .. label .. ")" end
    local r, g, b = 1, 0.1, 0.1 -- "??": much higher than you
    if level > 0 then
        local getColor = GetCreatureDifficultyColor or GetQuestDifficultyColor
        local ok, color = pcall(getColor, level)
        if ok and color then r, g, b = color.r, color.g, color.b end
    end
    return string.format("|cff%02x%02x%02x(%s)|r", r * 255, g * 255, b * 255, label)
end

---------------------------------------------------------------------------
-- Objects in the world (herbs, ore veins, chests...)
---------------------------------------------------------------------------
-- They aren't characters, so there's no "mouseover" for them, but the game
-- fills its tooltip with their data: the name on the first line and, for
-- gathering nodes, the profession on another line ("Mining", "Herbalism").
-- That data is read each time the tooltip is filled for an object, and the
-- profession line decides the category.
local PROFESSION_WORDS = {
    herb = { "herbalism", "herboristería", "herborismo", "herboristerie", "kräuterkunde",
             "травничество", "약초 채집", "草药学", "草藥學" },
    ore  = { "mining", "minería", "mineração", "minage", "bergbau",
             "горное дело", "채광", "采矿", "採礦" },
}

local hoveredObject -- { name, category, r, g, b } while the tooltip shows one

local function ObjectCategory(lines)
    for i = 2, #lines do
        local text = lines[i].leftText
        if type(text) == "string" and not ns.IsSecret(text) then
            text = text:lower()
            for category, words in pairs(PROFESSION_WORDS) do
                for _, word in ipairs(words) do
                    if text:find(word, 1, true) then return category end
                end
            end
        end
    end
    return "other"
end

local function RecordObject(data)
    hoveredObject = nil
    local lines = data and data.lines
    local first = lines and lines[1]
    local name = first and first.leftText
    if type(name) ~= "string" or ns.IsSecret(name) or name == "" then return end
    local r, g, b = 1, 1, 1
    local color = first.leftColor
    if color and color.r and not ns.IsSecret(color.r) then r, g, b = color.r, color.g, color.b end
    hoveredObject = { name = name, category = ObjectCategory(lines), r = r, g = g, b = b }
end

local OBJECT_TYPE = (Enum and Enum.TooltipDataType and Enum.TooltipDataType.Object) or 4

-- Best way: the game tells addons each time it fills a tooltip with data.
-- If this version can't, the data under the cursor is read a few times a
-- second while the tooltip shows (see WantsObject).
local listening = false
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
    listening = pcall(TooltipDataProcessor.AddTooltipPostCall, OBJECT_TYPE, function(tooltip, data)
        if tooltip == GameTooltip then RecordObject(data) end
    end)
end
local nextLook = 0
GameTooltip:HookScript("OnHide", function() hoveredObject = nil end)

local CATEGORY_SETTING = { herb = "objHerbs", ore = "objOre", other = "objOther" }

-- True if the object under the mouse should get its name at the cursor.
-- The game fades an object's tooltip out slowly after the mouse leaves it,
-- so the tooltip being shown doesn't mean the object is still there. While a
-- gathering node's name is up (herbs and ore), what's under the cursor is
-- checked often, and the name goes as soon as the node isn't under it. Other
-- objects keep their name until their tooltip is gone.
local LOOK_EVERY = 0.1
local QUICK_CATEGORIES = { herb = true, ore = true }

local function WantsObject()
    local db = mod.db
    if not GameTooltip:IsShown() or Yes(UnitExists("mouseover")) then return false end
    local canLook = C_TooltipInfo and C_TooltipInfo.GetWorldCursor
    local quick = hoveredObject and QUICK_CATEGORIES[hoveredObject.category]
    if canLook and (quick or not listening) and GetTime() >= nextLook then
        nextLook = GetTime() + LOOK_EVERY
        local ok, data = pcall(C_TooltipInfo.GetWorldCursor)
        if ok and data and data.type == OBJECT_TYPE then
            if not listening or not hoveredObject then RecordObject(data) end
        else
            hoveredObject = nil
        end
    end
    if not hoveredObject then return false end
    if not db[CATEGORY_SETTING[hoveredObject.category]] then return false end
    if not MouseOverWorld() then return false end
    if db.hideCombat and (InCombatLockdown() or Yes(UnitAffectingCombat("player"))) then return false end
    if db.hideInstances then
        local inInstance, kind = IsInInstance()
        if inInstance and kind ~= "none" then return false end
    end
    return true
end

-- True for NPCs you can't attack (vendors, trainers, guards...). nil if
-- the game keeps it secret.
local function IsFriendlyNpc()
    local isPlayer = UnitIsPlayer("mouseover")
    local canAttack = UnitCanAttack("player", "mouseover")
    if ns.IsSecret(isPlayer) or ns.IsSecret(canAttack) then return nil end
    return not isPlayer and not canAttack
end

-- True if a tooltip line is the "Level 19 Humanoid" line, not a title.
local function IsLevelLine(line)
    local word = LEVEL or "Level"
    return line:find(word, 1, true) ~= nil and line:find("%d") ~= nil
        or line:find(word .. " ??", 1, true) ~= nil
end

-- Title of the hovered NPC, like "Food & Drink Vendor": the second line of
-- the game's tooltip data, when it isn't the level line. nil if there's
-- none or it can't be read.
local function NpcTitle()
    local second
    if C_TooltipInfo and C_TooltipInfo.GetUnit then
        local ok, data = pcall(C_TooltipInfo.GetUnit, "mouseover")
        if ok and data and data.lines and data.lines[2] then
            second = data.lines[2].leftText
        end
    end
    -- Older clients: the tooltip on screen, if it shows this NPC.
    if second == nil and GameTooltip:IsShown() and GameTooltipTextLeft2 then
        local ok, _, unit = pcall(GameTooltip.GetUnit, GameTooltip)
        if ok and unit and not ns.IsSecret(unit) and Yes(UnitIsUnit(unit, "mouseover")) then
            second = GameTooltipTextLeft2:GetText()
        end
    end
    if second == nil or ns.IsSecret(second) or type(second) ~= "string" or second == "" then return nil end
    if IsLevelLine(second) then return nil end
    return second
end

local function SetFromObject()
    local o = hoveredObject
    title:Hide()
    PlaceText()
    text:SetText(o.name)
    text:SetTextColor(o.r, o.g, o.b)
    mark:Hide()
    hoveredName = o.name
end

local function SetFromMouseover()
    local name = UnitName("mouseover")
    if ns.IsSecret(name) then
        pcall(text.SetText, text, name) -- can't be read, but can be shown
        hoveredName = "?"
    else
        local shown = name or ""
        if mod.db.showLevel and (mod.db.npcLevel or IsFriendlyNpc() ~= true) then
            local level = LevelText()
            if level then shown = shown .. " " .. level end
        end
        text:SetText(shown)
        hoveredName = name or "?"
    end
    local ok, r, g, b = pcall(UnitSelectionColor, "mouseover")
    if not ok or ns.IsSecret(r) or ns.IsSecret(g) or ns.IsSecret(b) or not r then
        r, g, b = 1, 0.82, 0
    end
    mark:SetShown(mod.db.questMark and IsQuestRelated())

    -- Friendly players come back as pure blue, but the game draws their
    -- names in a lighter blue (measured in game: 102, 102, 255).
    if r < 0.05 and g < 0.05 and b > 0.95 then
        r, g, b = 0.4, 0.4, 1
    end
    text:SetTextColor(r, g, b)

    local npcTitle = mod.db.npcTitle and IsFriendlyNpc() and NpcTitle()
    if npcTitle then
        title:SetText("<" .. npcTitle .. ">")
        title:SetTextColor(r, g, b)
        title:Show()
    else
        title:Hide()
    end
    PlaceText()
end

local lastGUID
local UpdateTooltipDelay -- defined in the tooltip section
local UpdateToggleButton -- defined in the quick toggle section
local UpdateAutoRules    -- defined in the "hide automatically" section

function mod.OnTick(now)
    UpdateTooltipDelay(now)
    UpdateToggleButton(now)
    UpdateAutoRules(now)
    local db = mod.db
    -- What's under the mouse: a character first, otherwise an object.
    local key, fill
    if db.enabled and db.cursorName then
        if WantsHovered() then
            local guid = UnitGUID("mouseover")
            if ns.IsSecret(guid) then guid = nil end
            key, fill = guid or "unit", SetFromMouseover
            if guid == nil then lastGUID = nil end -- can't tell characters apart: refresh every time
        elseif WantsObject() then
            key, fill = "object:" .. hoveredObject.name, SetFromObject
        end
    end
    local want = key ~= nil
    if want then
        hoverStart = hoverStart or now
        if not showing and now - hoverStart < db.delay / 10 then return end
        hoverUntil = now + LINGER
        if not showing or key ~= lastGUID then
            fill()
            lastGUID = key
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
-- character, NPC or object), it stays invisible for the tooltip delay
-- (separate from the name delay). Tooltips of buttons and windows are never delayed. The tooltip is
-- kept invisible every frame, because the game sets its opacity itself.
local tooltipHooked = false
local tooltipPendingUntil -- time the delayed tooltip becomes visible

local function DelayTooltip(tooltip)
    local db = mod.db
    if not (db and db.enabled) or db.tooltipDelay <= 0 then return end
    if not MouseOverWorld() then return end
    tooltipPendingUntil = GetTime() + db.tooltipDelay / 10
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
-- Names above heads (the game's own settings)
---------------------------------------------------------------------------
-- Each option is one or more game variables. "invert" means the variable
-- hides names when on (UnitNameForceHideMinus), so the checkbox shows the
-- opposite. "toggle" options are hidden by "Hide all names".
local WORLD_NAMES = {
    { key = "wAlliedPlayers",     cvars = { "UnitNameFriendlyPlayerName" }, toggle = true },
    { key = "wEnemyPlayers",      cvars = { "UnitNameEnemyPlayerName" }, toggle = true },
    { key = "wHostileNpcs",       cvars = { "UnitNameHostleNPC" }, toggle = true },
    { key = "wInteractiveNpcs",   cvars = { "UnitNameInteractiveNPC" }, toggle = true },
    { key = "wSpecialNpcs",       cvars = { "UnitNameFriendlySpecialNPCName" }, toggle = true },
    { key = "wAllNpcs",           cvars = { "UnitNameNPC" }, toggle = true },
    { key = "wPets",              cvars = { "UnitNameFriendlyPetName", "UnitNameEnemyPetName" }, toggle = true },
    { key = "wMinions",           cvars = { "UnitNameFriendlyGuardianName", "UnitNameEnemyGuardianName",
                                            "UnitNameFriendlyMinionName", "UnitNameEnemyMinionName" }, toggle = true },
    { key = "wTotems",            cvars = { "UnitNameFriendlyTotemName", "UnitNameEnemyTotemName" }, toggle = true },
    { key = "wCritters",          cvars = { "UnitNameNonCombatCreatureName" }, toggle = true },
    { key = "wOwn",               cvars = { "UnitNameOwn" }, toggle = true },
    { key = "wWeak",              cvars = { "UnitNameForceHideMinus" }, invert = true },
    { key = "wGuild",             cvars = { "UnitNamePlayerGuild" } },
    { key = "wTitles",            cvars = { "UnitNamePlayerPVPTitle" } },
}

local function CVarExists(name)
    return GetCVar(name) ~= nil
end

-- An option is available if at least one of its variables exists here.
local function OptionAvailable(option)
    for _, name in ipairs(option.cvars) do
        if CVarExists(name) then return true end
    end
    return false
end

-- On if its first existing variable is on (or off, for inverted options).
local function OptionOn(option)
    for _, name in ipairs(option.cvars) do
        local value = GetCVar(name)
        if value ~= nil then
            local on = value == "1"
            if option.invert then on = not on end
            return on
        end
    end
    return false
end

local function SetOption(option, on)
    local value = on
    if option.invert then value = not on end
    for _, name in ipairs(option.cvars) do
        if CVarExists(name) then pcall(SetCVar, name, value and "1" or "0") end
    end
end

local function NamesHidden()
    return mod.db.worldNamesSaved ~= nil
end

-- Hides every "toggle" category, saving each variable's value, or puts the
-- saved values back. The saved values survive logging out.
local function ToggleWorldNames()
    local db = mod.db
    if db.worldNamesSaved then
        for name, value in pairs(db.worldNamesSaved) do
            if CVarExists(name) then pcall(SetCVar, name, value) end
        end
        db.worldNamesSaved = nil
        return true
    end
    local saved = {}
    for _, option in ipairs(WORLD_NAMES) do
        if option.toggle then
            for _, name in ipairs(option.cvars) do
                local value = GetCVar(name)
                if value ~= nil then
                    saved[name] = value
                    pcall(SetCVar, name, "0")
                end
            end
        end
    end
    db.worldNamesSaved = saved
    return false
end

---------------------------------------------------------------------------
-- Never left hidden after the game closes
---------------------------------------------------------------------------
-- The quick toggle hides names by changing game settings (CVars), and the
-- game keeps those settings after it closes. Two safeguards:
--   * Logging out or closing normally while names are hidden: they're put
--     back right before the game saves its settings (PLAYER_LOGOUT).
--   * A crash while hidden: this addon's saved data isn't written, so it
--     doesn't know names were hidden. At every normal logout it keeps a copy
--     of the name settings as they were (namesSnapshot). At login, if every
--     setting the quick toggle hides is off but that copy had some on, the
--     game most likely closed while they were hidden, and the copy is put
--     back.
-- Copying settings to another character (Core's settings per character):
-- whether names are hidden right now belongs to this session, not to the
-- settings. The copy never says names are hidden, and keeps this
-- character's own copy of the name settings for crash recovery.
function mod.OnCopy(new, current)
    new.worldNamesSaved = nil
    new.autoReason = nil
    new.namesSnapshot = current and ns.DeepCopy(current.namesSnapshot) or nil
end

local function ToggleCVarNames()
    local list = {}
    for _, option in ipairs(WORLD_NAMES) do
        if option.toggle then
            for _, name in ipairs(option.cvars) do
                if CVarExists(name) then list[#list + 1] = name end
            end
        end
    end
    return list
end

local function OnLogout()
    local db = mod.db
    if not db then return end
    if db.worldNamesSaved then
        for name, value in pairs(db.worldNamesSaved) do
            if CVarExists(name) then pcall(SetCVar, name, value) end
        end
        db.worldNamesSaved = nil
    end
    db.autoReason = nil
    local snapshot = {}
    for _, name in ipairs(ToggleCVarNames()) do snapshot[name] = GetCVar(name) end
    db.namesSnapshot = snapshot
end

-- Returns true if names had to be shown again.
local function RecoverNames()
    local db = mod.db
    -- Hidden when the game closed, and the addon knows it.
    if db.worldNamesSaved then
        for name, value in pairs(db.worldNamesSaved) do
            if CVarExists(name) then pcall(SetCVar, name, value) end
        end
        db.worldNamesSaved = nil
        db.autoReason = nil
        return true
    end
    -- Hidden when the game crashed: everything off, but not at the last logout.
    local snapshot = db.namesSnapshot
    if type(snapshot) ~= "table" then return false end
    local names = ToggleCVarNames()
    if #names == 0 then return false end
    for _, name in ipairs(names) do
        if GetCVar(name) ~= "0" then return false end
    end
    local anyOn = false
    for _, value in pairs(snapshot) do
        if value ~= "0" then anyOn = true end
    end
    if not anyOn then return false end
    for name, value in pairs(snapshot) do
        if CVarExists(name) then pcall(SetCVar, name, value) end
    end
    return true
end

local logoutEvents = CreateFrame("Frame")
logoutEvents:RegisterEvent("PLAYER_LOGOUT")
logoutEvents:SetScript("OnEvent", OnLogout)

---------------------------------------------------------------------------
-- Quick toggle: button on screen
---------------------------------------------------------------------------
local optionRefreshers = {} -- open option pages, refreshed after a toggle
local BUTTON_LINGER = 0.3

-- The button belongs to the world frame, not to the interface, so it stays
-- visible when "Names and interface" hides the interface. It uses the
-- interface's scale so its size matches everything else.
local toggle = CreateFrame("Button", "UIVisibilityNamesButton", WorldFrame)
toggle:SetFrameStrata("MEDIUM")
toggle:SetClampedToScreen(true)
toggle:SetMovable(true)
toggle:RegisterForDrag("LeftButton")
toggle:RegisterForClicks("LeftButtonUp")
toggle:SetAlpha(0)
toggle:Hide()

-- A plain, gray look so the button doesn't stand out on screen.
local toggleBorder = toggle:CreateTexture(nil, "BACKGROUND")
toggleBorder:SetPoint("TOPLEFT", -1, 1)
toggleBorder:SetPoint("BOTTOMRIGHT", 1, -1)
toggleBorder:SetColorTexture(0, 0, 0, 0.5)

local toggleIcon = toggle:CreateTexture(nil, "ARTWORK")
toggleIcon:SetAllPoints()
toggleIcon:SetTexture("Interface\\Icons\\Spell_Holy_MindVision")
toggleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
toggleIcon:SetDesaturated(true)

local toggleCross = toggle:CreateTexture(nil, "OVERLAY")
toggleCross:SetPoint("CENTER")
toggleCross:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
toggleCross:SetDesaturated(true)
toggleCross:SetVertexColor(0.85, 0.85, 0.85)

toggle:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- Two looks, both gray so the button doesn't stand out:
--   style_eye:   a plain drawn eye, open while names are shown and crossed
--                out while they're hidden (Media\EyeOpen and EyeClosed).
--   style_spell: the game's Mind Vision icon in gray, darker and with a
--                cross while names are hidden.
local MEDIA = "Interface\\AddOns\\UIVisibility\\Media\\"
local SPELL_ICON = "Interface\\Icons\\Spell_Holy_MindVision"

local function UpdateToggleLook()
    local db = mod.db
    local hidden = db and db.worldNamesSaved ~= nil
    local highlight = toggle:GetHighlightTexture()
    if db and db.buttonStyle == "style_spell" then
        toggleBorder:Show()
        toggleIcon:SetTexture(SPELL_ICON)
        toggleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        toggleIcon:SetDesaturated(true)
        if hidden then
            toggleIcon:SetVertexColor(0.4, 0.4, 0.4)
        else
            toggleIcon:SetVertexColor(0.85, 0.85, 0.85)
        end
        toggleCross:SetShown(hidden)
        highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        highlight:SetTexCoord(0, 1, 0, 1)
        highlight:SetAlpha(1)
    else
        local texture = MEDIA .. (hidden and "EyeClosed" or "EyeOpen")
        toggleBorder:Hide()
        toggleIcon:SetTexture(texture)
        toggleIcon:SetTexCoord(0, 1, 0, 1)
        toggleIcon:SetDesaturated(false)
        if hidden then
            toggleIcon:SetVertexColor(0.5, 0.5, 0.5)
        else
            toggleIcon:SetVertexColor(0.8, 0.8, 0.8)
        end
        toggleCross:Hide()
        -- On hover, the eye itself lights up instead of a square glow.
        highlight:SetTexture(texture)
        highlight:SetTexCoord(0, 1, 0, 1)
        highlight:SetAlpha(0.35)
    end
end

local function ShowToggleTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.nm_secWorld, 1, 0.82, 0)
    GameTooltip:AddLine(mod.db.worldNamesSaved and L.nm_btnHidden or L.nm_btnShown, 1, 1, 1, true)
    GameTooltip:AddLine(L.nm_btnMove, 0.6, 0.6, 0.6, true)
    GameTooltip:Show()
end

-- Toggles the names and updates everything that shows their state.
-- Returns true if names are shown again, false if hidden, and nil if the
-- interface part had to wait because of combat (then nothing changes).
local ToggleAll
local lastActive = GetTime() -- last moment the player did something
local uiHiddenByAddon = false -- this addon hid the interface
local escPending = false      -- Esc showed it; hide it again when menus close

-- Chat while the interface is hidden
-- Hiding everything hides UIParent, and the chat (with its typing box) is
-- inside it, so pressing Enter opened an invisible box. While the interface
-- is hidden by this addon, the chat window being typed in is moved to a
-- holder outside UIParent (same size and scale), so it shows. When the box
-- closes, or the interface comes back, it goes back to its own parent.
-- Chat frames aren't protected, so this also works in combat.
local chatHolder
local liftedChat = {} -- frame -> its original parent

local function ChatHolder()
    if not chatHolder then
        chatHolder = CreateFrame("Frame", nil, WorldFrame)
    end
    local worldScale = WorldFrame:GetEffectiveScale()
    chatHolder:SetScale(worldScale > 0 and UIParent:GetEffectiveScale() / worldScale or UIParent:GetScale())
    chatHolder:ClearAllPoints()
    chatHolder:SetAllPoints(UIParent)
    chatHolder:Show()
    return chatHolder
end

local function LiftChat(frame)
    if not frame or liftedChat[frame] or not frame.SetParent then return end
    liftedChat[frame] = frame:GetParent()
    frame:SetParent(ChatHolder())
end

local function DropChat()
    for frame, parent in pairs(liftedChat) do frame:SetParent(parent) end
    wipe(liftedChat)
end

local chatDebug = { opened = 0, closed = 0, last = "none" } -- for /uiv names chat

local function OnChatOpened(editBox)
    if not uiHiddenByAddon or UIParent:IsShown() then return end
    if type(editBox) ~= "table" or not editBox.GetParent then
        editBox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow() or nil
    end
    if type(editBox) ~= "table" or not editBox.GetParent then return end
    local chat = editBox.chatFrame or editBox:GetParent()
    if liftedChat[chat] or liftedChat[editBox] then return end -- already out
    chatDebug.opened = chatDebug.opened + 1
    chatDebug.last = editBox.GetName and editBox:GetName() or "?"
    if chat and chat ~= UIParent then LiftChat(chat) end
    -- In some layouts the box isn't inside its chat window.
    if editBox:GetParent() ~= chat then LiftChat(editBox) end
end

local ActiveChatBox -- defined below

-- Only once no chat box is being typed in: moving the chat can make the box
-- lose focus for a moment, which must not send it back right away.
local function OnChatClosed()
    if next(liftedChat) and not (ActiveChatBox and ActiveChatBox()) then
        chatDebug.closed = chatDebug.closed + 1
        DropChat()
    end
end

-- The typing box itself is hooked: the moment the game shows it (Enter), the
-- chat is moved out, before the game gives it focus (an invisible box can't
-- take focus). The game's functions are hooked too where they exist, and
-- focus for layouts where the box stays shown (IM style).
local chatHooks = {}
local function HookChatBox(box)
    if not box or chatHooks[box] or not box.HookScript then return end
    chatHooks[box] = true
    hooksecurefunc(box, "Show", OnChatOpened)
    hooksecurefunc(box, "Hide", OnChatClosed)
    hooksecurefunc(box, "SetShown", function(self, shown)
        if shown then OnChatOpened(self) else OnChatClosed() end
    end)
    box:HookScript("OnEditFocusGained", OnChatOpened)
    box:HookScript("OnEditFocusLost", OnChatClosed)
end
for i = 1, (NUM_CHAT_WINDOWS or 10) do HookChatBox(_G["ChatFrame" .. i .. "EditBox"]) end
if ChatEdit_ActivateChat then hooksecurefunc("ChatEdit_ActivateChat", OnChatOpened) end
if ChatEdit_DeactivateChat then hooksecurefunc("ChatEdit_DeactivateChat", OnChatClosed) end
if type(ChatFrameUtil) == "table" then
    if ChatFrameUtil.ActivateChat then hooksecurefunc(ChatFrameUtil, "ActivateChat", OnChatOpened) end
    if ChatFrameUtil.DeactivateChat then hooksecurefunc(ChatFrameUtil, "DeactivateChat", OnChatClosed) end
end

-- Safety check, only while everything is hidden (every tick, about 20 times
-- a second, so the chat shows right away): asks the game which chat box is
-- being typed in, in case it was opened in a way none of the hooks catch.
function ActiveChatBox()
    local get = ChatEdit_GetActiveWindow
        or (type(ChatFrameUtil) == "table" and ChatFrameUtil.GetActiveWindow)
    local ok, box = false, nil
    if get then ok, box = pcall(get) end
    if ok and type(box) == "table" and box.GetParent then return box end
    for b in pairs(chatHooks) do
        if b.HasFocus and b:HasFocus() then return b end
    end
    return nil
end

local function UpdateChatWhileHidden()
    if not uiHiddenByAddon or UIParent:IsShown() then return end
    local box = ActiveChatBox()
    if box then
        OnChatOpened(box)
    elseif next(liftedChat) then
        OnChatClosed()
    end
end

-- /uiv names chat: why the chat does or doesn't show while everything is hidden.
local function PrintChatDebug()
    local box = ChatFrame1EditBox
    local function name(f) return f and (f.GetName and f:GetName() or "?") or "none" end
    ns.Print(string.format("hidden by addon %s, UIParent shown %s, chat style %s",
        tostring(uiHiddenByAddon), tostring(UIParent:IsShown()), tostring(GetCVar and GetCVar("chatStyle"))))
    ns.Print(string.format("active box now: %s", name(ActiveChatBox())))
    ns.Print(string.format("hooks: ChatEdit_ActivateChat %s, ChatFrameUtil.ActivateChat %s, boxes %d",
        tostring(ChatEdit_ActivateChat ~= nil),
        tostring(type(ChatFrameUtil) == "table" and ChatFrameUtil.ActivateChat ~= nil), (function()
            local n = 0 for _ in pairs(chatHooks) do n = n + 1 end return n end)()))
    if box then
        ns.Print(string.format("ChatFrame1EditBox: parent %s, chatFrame %s, shown %s, visible %s, focus %s",
            name(box:GetParent()), name(box.chatFrame), tostring(box:IsShown()), tostring(box:IsVisible()),
            tostring(box.HasFocus and box:HasFocus())))
    end
    local lifted = {}
    for frame in pairs(liftedChat) do lifted[#lifted + 1] = name(frame) end
    ns.Print(string.format("opened %d, closed %d, last box %s, moved now: %s", chatDebug.opened, chatDebug.closed,
        chatDebug.last, #lifted > 0 and table.concat(lifted, ", ") or "none"))
end

-- What the player does by hand (buttons and command). It also forgets any
-- automatic reason, so automatic rules never undo a manual choice, and
-- restarts the "time out of combat" count, so showing everything by hand
-- isn't followed by an instant hide.
local function ManualToggle()
    local result = ToggleAll()
    if result ~= nil then
        mod.db.autoReason = nil
        lastActive = GetTime()
    end
    return result
end

function ToggleAll()
    local db = mod.db
    local hiding = db.worldNamesSaved == nil
    local uiHidden = not UIParent:IsShown()
    local touchesUI = (hiding and db.quickTarget == "target_all") or (not hiding and uiHidden)
    if touchesUI and InCombatLockdown() then
        ns.Print(L.nm_combatBlocked)
        return nil
    end
    local shownAgain = ToggleWorldNames()
    if shownAgain then
        -- Bringing names back always brings the interface back too.
        DropChat()
        if uiHidden then UIParent:Show() end
        uiHiddenByAddon, escPending = false, false
    elseif db.quickTarget == "target_all" then
        UIParent:Hide()
        uiHiddenByAddon = true
    end
    UpdateToggleLook()
    for _, refresh in ipairs(optionRefreshers) do refresh() end
    if toggle:IsMouseOver() and GameTooltip:IsOwned(toggle) then ShowToggleTooltip(toggle) end
    return shownAgain
end

local function ApplyToggleLayout()
    local db = mod.db
    toggle:SetScale(UIParent:GetScale())
    toggle:SetSize(db.buttonSize, db.buttonSize)
    toggleCross:SetSize(db.buttonSize * 0.7, db.buttonSize * 0.7)
    toggle:ClearAllPoints()
    local p = db.buttonPoint
    if p then
        toggle:SetPoint(p[1], WorldFrame, p[2], p[3], p[4])
    else
        toggle:SetPoint("CENTER", WorldFrame, "CENTER", 0, 200)
    end
    UpdateToggleLook()
end

-- Keep the button's size and place when the interface scale or the screen
-- size changes.
local layoutEvents = CreateFrame("Frame")
layoutEvents:RegisterEvent("UI_SCALE_CHANGED")
layoutEvents:RegisterEvent("DISPLAY_SIZE_CHANGED")
layoutEvents:SetScript("OnEvent", function()
    if mod.db then ApplyToggleLayout() end
end)

toggle:SetScript("OnClick", function()
    if IsShiftKeyDown() then return end -- Shift is for moving
    ManualToggle()
end)
toggle:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() then self:StartMoving() end
end)
toggle:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint(1)
    mod.db.buttonPoint = { point, relativePoint, x, y }
end)
toggle:SetScript("OnEnter", ShowToggleTooltip)
toggle:SetScript("OnLeave", function() GameTooltip:Hide() end)

local toggleHoverUntil = 0

-- Called every tick: shows, hides and fades the button.
function UpdateToggleButton(now)
    local db = mod.db
    if not (db and db.enabled and db.showButton) then
        if toggle:IsShown() then toggle:Hide() end
        return
    end
    if not toggle:IsShown() then
        toggle:SetAlpha(db.buttonMode == "hover" and db.buttonIdleAlpha / 100 or 1)
        toggle:Show()
    end
    local target = 1
    if db.buttonMode == "hover" and not ns.IsEditMode() then
        if ns.IsCursorOver(toggle) then toggleHoverUntil = now + BUTTON_LINGER end
        if now >= toggleHoverUntil then target = db.buttonIdleAlpha / 100 end
    end
    ns.Fade(toggle, target)
end

---------------------------------------------------------------------------
-- Hide automatically
---------------------------------------------------------------------------
-- Hides for a reason ("afk" or "idle") if everything is shown, and shows
-- again only if it was hidden for that same reason.
local function AutoHide(reason)
    local db = mod.db
    if db.worldNamesSaved then return end
    if ToggleAll() == false then db.autoReason = reason end
end

local function AutoShow(reason)
    local db = mod.db
    if not db.worldNamesSaved or db.autoReason ~= reason then return end
    if ToggleAll() == true then db.autoReason = nil end
end

local lastCursorX, lastCursorY = 0, 0

local function UpdateAfk()
    local db = mod.db
    if not db then return end
    local away = UnitIsAFK("player")
    if ns.IsSecret(away) then return end
    if db.enabled and db.autoAfk and away then
        AutoHide("afk")
    else
        AutoShow("afk")
    end
end

-- True while you're using the interface: this addon's options, the game's
-- options or menu, or typing in chat. Time spent there never counts.
-- Uses IsVisible, so windows that are open but hidden with the interface
-- (like the chat box after pressing Enter) don't count.
local function UsingInterface()
    if UIVisibilityWindow and UIVisibilityWindow:IsVisible() then return true end
    if SettingsPanel and SettingsPanel:IsVisible() then return true end
    if GameMenuFrame and GameMenuFrame:IsVisible() then return true end
    local editBox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
    return editBox ~= nil and editBox:IsVisible()
end

-- True if the mouse moved since the last check.
local function CursorMoved()
    local x, y = GetCursorPosition()
    local moved = math.abs(x - lastCursorX) > 2 or math.abs(y - lastCursorY) > 2
    lastCursorX, lastCursorY = x, y
    return moved
end

-- Called every tick: the "time out of combat" rule.
local function UpdateIdle(now)
    local db = mod.db
    local cursorMoved = CursorMoved()
    if not (db.enabled and db.autoIdle) then
        AutoShow("idle")
        return
    end
    if InCombatLockdown() then
        lastActive = now
        return
    end
    -- Moving the character always comes first, so it shows everything again
    -- even while the chat box or a window is open.
    if db.autoStill and GetUnitSpeed("player") > 0 then
        lastActive = now
        AutoShow("idle")
        return
    end
    if UsingInterface() then
        lastActive = now
        return
    end
    if db.autoStill then
        if cursorMoved then
            -- The mouse always stops the count; it only undoes the hide if
            -- the player chose that.
            lastActive = now
            if db.autoMouseShows then AutoShow("idle") end
            return
        end
    end
    if now - lastActive >= db.autoIdleTime then AutoHide("idle") end
end

-- Pressing Esc while the interface is hidden makes the game show all of it
-- with the menu (the menu is part of the interface, so it can't show alone).
-- When the menu, and any window opened from it, is closed again, the
-- interface goes back to hidden.
-- True if any menu or window is open. Besides the known ones, it checks the
-- game's lists of panels and of windows that close with Esc, so it finds the
-- system menu whatever it's called in this version of the game.
local PANEL_AREAS = { "left", "center", "right", "doublewide", "fullscreen" }

local function MenusOpen()
    for _, name in ipairs({ "GameMenuFrame", "SettingsPanel", "AddonList",
        "UIVisibilityWindow", "HelpFrame", "MacroFrame" }) do
        local frame = _G[name]
        if frame and frame.IsShown and frame:IsShown() then return true end
    end
    if GetUIPanel then
        for _, area in ipairs(PANEL_AREAS) do
            local ok, panel = pcall(GetUIPanel, area)
            if ok and panel then return true end
        end
    end
    if UISpecialFrames then
        for _, name in ipairs(UISpecialFrames) do
            local frame = _G[name]
            if frame and frame.IsShown and frame:IsShown() then return true end
        end
    end
    return ns.IsEditMode()
end

-- Esc while hidden: wait for the menu to appear, then for it (and anything
-- opened from it) to close, and hide the interface again. If no menu shows
-- up at all, Esc just brought the interface back, so the names come back
-- too and nothing is left half hidden.
local escStarted = 0
local menuSeen = false
local MENU_WAIT = 0.5

if ToggleGameMenu then
    hooksecurefunc("ToggleGameMenu", function()
        if uiHiddenByAddon and UIParent:IsShown() and not escPending then
            escPending, menuSeen, escStarted = true, false, GetTime()
        end
    end)
end

local function UpdateEscape(now)
    if not escPending then return end
    if not uiHiddenByAddon or not mod.db.worldNamesSaved then
        escPending = false
        return
    end
    if MenusOpen() then
        menuSeen = true
        return
    end
    if not menuSeen then
        if now - escStarted < MENU_WAIT then return end
        -- No menu: treat Esc as "show everything".
        escPending = false
        if not UIParent:IsShown() then return end
        uiHiddenByAddon = false
        DropChat()
        ToggleAll()
        mod.db.autoReason = nil
        lastActive = now
        return
    end
    if InCombatLockdown() then return end
    escPending = false
    if UIParent:IsShown() then UIParent:Hide() end
end

function UpdateAutoRules(now)
    if mod.db then
        UpdateIdle(now)
        UpdateEscape(now)
        UpdateChatWhileHidden()
    end
end

local autoEvents = CreateFrame("Frame")
autoEvents:RegisterEvent("PLAYER_FLAGS_CHANGED")
autoEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
autoEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
autoEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
autoEvents:SetScript("OnEvent", function(self, event, unit)
    if not mod.db then return end
    if event == "PLAYER_REGEN_DISABLED" then
        -- Runs just before combat locks the interface, so it can still be
        -- shown here.
        lastActive = GetTime()
        AutoShow("idle")
    elseif event == "PLAYER_REGEN_ENABLED" then
        lastActive = GetTime()
    elseif event == "PLAYER_ENTERING_WORLD" then
        lastActive = GetTime()
        UpdateAfk()
    elseif unit == "player" then
        UpdateAfk()
    end
end)

---------------------------------------------------------------------------
-- Module hooks
---------------------------------------------------------------------------
function mod.SetEnabled(v)
    mod.db.enabled = v
end

function mod.OnLogin()
    if RecoverNames() then ns.Print(L.nm_recovered) end
    ApplyFont()
    ApplyToggleLayout()
    HookTooltip()
    -- Earlier versions could leave the minimum name size raised.
    if mod.db.savedSize ~= nil then
        pcall(SetCVar, "WorldTextMinSize", tostring(mod.db.savedSize))
        mod.db.savedSize = nil
    end
    mod.db.fallbackAll, mod.db.fallbackSize = nil, nil
    local db = mod.db
    if db.players ~= nil or db.npcs ~= nil or db.enemies ~= nil then
        local players = db.players ~= false
        local npcs = db.npcs ~= false
        local enemies = db.enemies ~= false
        db.alliedPlayers = players
        db.enemyPlayers = players and enemies
        db.friendlyNpcs = npcs
        db.hostileNpcs = npcs and enemies
        db.players, db.npcs, db.enemies = nil, nil, nil
    end
end

function mod.BuildOptions(parent, y)
    local refreshers = {}
    local function add(r) refreshers[#refreshers + 1] = r end
    local function refreshAll() for _, r in ipairs(refreshers) do r() end end
    local function set(key) return function(v) mod.db[key] = v; refreshAll() end end
    local function db() return mod.db end

    local COL1, COL2, INDENT, WIDTH = 16, 216, 40, 160
    local nameOn = function() return db().cursorName end
    local levelOn = function() return db().cursorName and db().showLevel end

    add(ns.CreateCheck(parent, L.enabled, y,
        function() return db().enabled end, function(v) mod.SetEnabled(v); refreshAll() end, { master = true }))
    y = y - 40

    -- Name at the cursor
    ns.CreateSection(parent, L.nm_secName, y)
    y = y - 30
    add(ns.CreateCheck(parent, L.nm_cursorName, y,
        function() return db().cursorName end, set("cursorName"),
        { tooltip = L.nm_nameNote .. " " .. L.nm_cursorName_tip }))
    y = y - 34
    add(ns.CreateSlider(parent, L.nm_size, y,
        function() return db().size end,
        function(v) db().size = v; ApplyFont() end, 10, 40,
        function(v) return tostring(math.floor(v + 0.5)) end, { enabledIf = nameOn }))
    y = y - 32
    add(ns.CreateDropdown(parent, L.nm_position, y, POSITIONS,
        function() return db().position end,
        function(v) db().position = v; PlaceText() end, { enabledIf = nameOn, tooltip = L.nm_note }))
    y = y - 32
    add(ns.CreateStepper(parent, L.nm_delay, y,
        function() return db().delay end, set("delay"), 0, 10, 1,
        function(v) return string.format("%.1f s", v / 10) end, { enabledIf = nameOn }))
    y = y - 34

    -- What shows next to the name: one column, sub-options indented under
    -- the option they depend on.
    ns.CreateHeader(parent, L.nm_withName, y)
    y = y - 22
    add(ns.CreateCheck(parent, L.nm_showLevel, y,
        function() return db().showLevel end, set("showLevel"),
        { x = COL1, width = 300, tooltip = L.nm_showLevel_tip, enabledIf = nameOn }))
    y = y - 26
    add(ns.CreateCheck(parent, L.nm_levelColor, y,
        function() return db().levelColor end, set("levelColor"),
        { x = INDENT, width = 300, tooltip = L.nm_levelColor_tip, enabledIf = levelOn }))
    y = y - 26
    add(ns.CreateCheck(parent, L.nm_npcLevel, y,
        function() return db().npcLevel end, set("npcLevel"),
        { x = INDENT, width = 300, tooltip = L.nm_npcLevel_tip, enabledIf = levelOn }))
    y = y - 26
    add(ns.CreateCheck(parent, L.nm_npcTitle, y,
        function() return db().npcTitle end, set("npcTitle"),
        { x = COL1, width = 300, tooltip = L.nm_npcTitle_tip, enabledIf = nameOn }))
    y = y - 26
    add(ns.CreateCheck(parent, L.nm_questMark, y,
        function() return db().questMark end, set("questMark"),
        { x = COL1, width = 300, tooltip = L.nm_questMark_tip, enabledIf = nameOn }))
    y = y - 40

    -- Show for
    ns.CreateSection(parent, L.nm_secWho, y)
    y = y - 32
    for _, row in ipairs({
        { "alliedPlayers", "enemyPlayers" },
        { "friendlyNpcs", "hostileNpcs" },
    }) do
        for col, key in ipairs(row) do
            add(ns.CreateCheck(parent, L["nm_" .. key], y,
                function() return db()[key] end, set(key),
                { x = col == 1 and COL1 or COL2, width = WIDTH, grid = true,
                  tooltip = L["nm_" .. key .. "_tip"] ~= "nm_" .. key .. "_tip" and L["nm_" .. key .. "_tip"] or nil,
                  enabledIf = nameOn }))
        end
        y = y - 28
    end
    y = y - 12

    -- Objects
    ns.CreateSection(parent, L.nm_secObjects, y)
    y = y - 30
    for i, key in ipairs({ "objHerbs", "objOre", "objOther" }) do
        local col = (i - 1) % 2
        add(ns.CreateCheck(parent, L["nm_" .. key], y,
            function() return db()[key] end, set(key),
            { x = col == 0 and COL1 or COL2, width = WIDTH, grid = true,
              tooltip = L["nm_" .. key .. "_tip"], enabledIf = nameOn }))
        if col == 1 or i == 3 then y = y - 28 end
    end
    y = y - 12

    -- Hide when
    ns.CreateSection(parent, L.nm_secHide, y)
    y = y - 32
    for _, row in ipairs({
        { "hideCombat", "hideInstances" },
        { "skipDead", "skipPlates" },
        { "worldOnly" },
    }) do
        for col, key in ipairs(row) do
            local tip = L["nm_" .. key .. "_tip"]
            add(ns.CreateCheck(parent, L["nm_" .. key], y,
                function() return db()[key] end, set(key),
                { x = col == 1 and COL1 or COL2, width = WIDTH, grid = true,
                  tooltip = tip ~= "nm_" .. key .. "_tip" and tip or nil,
                  enabledIf = nameOn }))
        end
        y = y - 28
    end
    y = y - 12

    -- Names above heads
    ns.CreateSection(parent, L.nm_secWorld, y)
    y = y - 30
    local notHidden = function() return not NamesHidden() end
    local shown = {}
    for _, option in ipairs(WORLD_NAMES) do
        if OptionAvailable(option) then shown[#shown + 1] = option end
    end
    for i, option in ipairs(shown) do
        local col = (i - 1) % 2
        local tip = L["nm_" .. option.key .. "_tip"]
        add(ns.CreateCheck(parent, L["nm_" .. option.key], y,
            function() return OptionOn(option) end,
            function(v) SetOption(option, v); refreshAll() end,
            { x = col == 0 and COL1 or COL2, width = WIDTH, grid = true,
              tooltip = tip ~= "nm_" .. option.key .. "_tip" and tip or nil,
              enabledIf = notHidden }))
        if col == 1 or i == #shown then y = y - 28 end
    end
    y = y - 12

    -- Quick toggle
    ns.CreateSection(parent, L.nm_secQuick, y)
    y = y - 30
    add(ns.CreateDropdown(parent, L.nm_quickTarget, y, { "target_names", "target_all" },
        function() return db().quickTarget end, set("quickTarget"),
        { tooltip = L.nm_quickNote .. " " .. L.nm_quickTarget_tip }))
    y = y - 36
    local toggleButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    toggleButton:SetSize(220, 24)
    toggleButton:SetPoint("TOPLEFT", 20, y)
    toggleButton:SetScript("OnClick", function() ManualToggle() end)
    toggleButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self:GetText() or "", 1, 0.82, 0)
        GameTooltip:AddLine(L.nm_toggleNote, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    toggleButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    y = y - 30
    local stateNote = parent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    stateNote:SetPoint("TOPLEFT", 18, y)
    stateNote:SetWidth(380)
    stateNote:SetJustifyH("LEFT")
    -- Room for its text while names are hidden, so the next section never overlaps it.
    stateNote:SetText(L.nm_hiddenNote)
    local stateHeight = math.ceil(stateNote:GetStringHeight())
    add(function()
        toggleButton:SetEnabled(db().enabled)
        if NamesHidden() then
            toggleButton:SetText(L.nm_showAgain)
            stateNote:SetText(L.nm_hiddenNote)
        else
            toggleButton:SetText(L.nm_hideAll)
            stateNote:SetText("")
        end
    end)
    y = y - stateHeight - ns.NOTE_GAP

    ns.CreateSection(parent, L.nm_secButton, y)
    y = y - 32
    add(ns.CreateCheck(parent, L.nm_showButton, y,
        function() return db().showButton end, set("showButton"),
        { tooltip = L.nm_showButton_tip .. " " .. L.nm_moveNote }))
    y = y - 34
    local buttonOn = function() return db().showButton end
    add(ns.CreateDropdown(parent, L.nm_buttonStyle, y, { "style_eye", "style_spell" },
        function() return db().buttonStyle end,
        function(v) db().buttonStyle = v; UpdateToggleLook(); refreshAll() end,
        { x = INDENT, enabledIf = buttonOn }))
    y = y - 32
    add(ns.CreateDropdown(parent, L.nm_buttonMode, y, { "shown", "hover" },
        function() return db().buttonMode end, set("buttonMode"),
        { x = INDENT, enabledIf = buttonOn }))
    y = y - 32
    add(ns.CreateStepper(parent, L.nm_buttonIdle, y,
        function() return db().buttonIdleAlpha end, set("buttonIdleAlpha"), 0, 90, 10, "%",
        { x = INDENT, tooltip = L.nm_buttonIdle_tip,
          enabledIf = function() return buttonOn() and db().buttonMode == "hover" end }))
    y = y - 32
    add(ns.CreateSlider(parent, L.nm_buttonSize, y,
        function() return db().buttonSize end,
        function(v) db().buttonSize = v; ApplyToggleLayout() end, 20, 64,
        function(v) return tostring(math.floor(v + 0.5)) end,
        { x = INDENT, enabledIf = buttonOn }))
    y = y - 34
    local reset = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    reset:SetSize(160, 22)
    reset:SetPoint("TOPLEFT", 20, y)
    reset:SetText(L.nm_resetPos)
    reset:SetScript("OnClick", function()
        db().buttonPoint = nil
        ApplyToggleLayout()
    end)
    add(function() reset:SetEnabled(db().enabled and buttonOn()) end)
    y = y - 28

    -- Hide automatically
    ns.CreateSection(parent, L.nm_secAuto, y)
    y = y - 30
    add(ns.CreateCheck(parent, L.nm_autoAfk, y,
        function() return db().autoAfk end,
        function(v) db().autoAfk = v; UpdateAfk(); refreshAll() end,
        { tooltip = L.nm_autoAfk_tip .. " " .. L.nm_autoNote }))
    y = y - 28
    add(ns.CreateCheck(parent, L.nm_autoIdle, y,
        function() return db().autoIdle end, set("autoIdle"),
        { tooltip = L.nm_autoIdle_tip .. " " .. L.nm_autoNote }))
    y = y - 32
    add(ns.CreateStepper(parent, L.nm_autoIdleTime, y,
        function() return db().autoIdleTime end, set("autoIdleTime"), 10, 300, 10, " s",
        { x = 44, enabledIf = function() return db().autoIdle end }))
    y = y - 28
    add(ns.CreateCheck(parent, L.nm_autoStill, y,
        function() return db().autoStill end, set("autoStill"),
        { x = 40, tooltip = L.nm_autoStill_tip, enabledIf = function() return db().autoIdle end }))
    y = y - 28
    add(ns.CreateCheck(parent, L.nm_autoMouse, y,
        function() return db().autoMouseShows end, set("autoMouseShows"),
        { x = 64, tooltip = L.nm_autoMouse_tip,
          enabledIf = function() return db().autoIdle and db().autoStill end }))
    y = y - 40

    -- Tooltip
    ns.CreateSection(parent, L.nm_secTooltip, y)
    y = y - 30
    add(ns.CreateCheck(parent, L.nm_tooltipCursor, y,
        function() return db().tooltipCursor end, set("tooltipCursor"),
        { tooltip = L.nm_tooltipCursor_tip }))
    y = y - 34
    add(ns.CreateSlider(parent, L.nm_tooltipScale, y,
        function() return db().tooltipScale end, set("tooltipScale"), 50, 200,
        function(v) return math.floor(v + 0.5) .. "%" end))
    y = y - 32
    add(ns.CreateStepper(parent, L.nm_tooltipDelay, y,
        function() return db().tooltipDelay end, set("tooltipDelay"), 0, 10, 1,
        function(v) return string.format("%.1f s", v / 10) end, { tooltip = L.nm_tooltipNote }))
    y = y - 28

    optionRefreshers[#optionRefreshers + 1] = refreshAll
    return refreshAll
end

function mod.Command(cmd)
    if cmd == "chat" then PrintChatDebug(); return true end
    if cmd == "togglenames" then
        local result = ManualToggle()
        if result == true then
            ns.Print(L.nm_toggledOn)
        elseif result == false then
            ns.Print(L.nm_toggledOff)
        end
        return true
    end
    return false
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