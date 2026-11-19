-- UI Visibility: interface module
-- Chat, social button, quest tracker, Questie tracker, buffs, debuffs, bags
-- and micro menu, using the element engine.
--
-- The chat counts as one element made of several frames: every chat window
-- and its tab, the tab dock and the chat buttons. Hovering any of them shows
-- all of them, and the chat is always shown while you type a message.

local ADDON_NAME, ns = ...

ns.AddLocale("en", {
    tab_interface = "Interface",
    if_title = "Interface",
    if_chat = "Chat", if_social = "Social button", if_quests = "Quest tracker",
    if_questie = "Questie tracker",
    if_buffs = "Buffs", if_debuffs = "Debuffs", if_bags = "Bags", if_micro = "Main menu",
    if_note = "The chat always shows while you type.",
})
ns.AddLocale("es", {
    tab_interface = "Interfaz",
    if_title = "Interfaz",
    if_chat = "Chat", if_social = "Botón social", if_quests = "Misiones",
    if_questie = "Rastreador de Questie",
    if_buffs = "Beneficios", if_debuffs = "Perjuicios", if_bags = "Bolsas", if_micro = "Menú principal",
    if_note = "El chat siempre se muestra mientras escribes.",
})

local function FindChat()
    local list = {}
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        ns.AddFrame(list, _G["ChatFrame" .. i])
        ns.AddFrame(list, _G["ChatFrame" .. i .. "Tab"])
        ns.AddFrame(list, _G["ChatFrame" .. i .. "ButtonFrame"])
    end
    ns.AddFrame(list, GeneralDockManager)
    ns.AddFrame(list, ChatFrameMenuButton)
    ns.AddFrame(list, ChatFrameChannelButton)
    ns.AddFrame(list, TextToSpeechButtonFrame)
    return list
end

-- Questie's quest tracker. Questie_BaseFrame holds the whole tracker; if a
-- Questie version doesn't have it, the quest list itself (TrackedQuests) is
-- used. Questie can create it after login, so it's looked up again on the
-- slow tick like every other element.
local function FindQuestie()
    local list = {}
    if Questie_BaseFrame then
        ns.AddFrame(list, Questie_BaseFrame)
    else
        ns.AddFrame(list, TrackedQuests)
    end
    return list
end

-- True while a chat input box is open.
local function IsTyping()
    local editBox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
    return editBox ~= nil and editBox:IsShown()
end

ns.NewElementsModule({
    key = "interface", titleKey = "if_title", tabKey = "tab_interface",
    noteKey = "if_note",
    elements = {
        { key = "chat",    label = "if_chat",    find = FindChat, forceShow = IsTyping, multi = true },
        { key = "social",  label = "if_social",  frame = "QuickJoinToastButton" },
        { key = "quests",  label = "if_quests",  frame = "ObjectiveTrackerFrame" },
        { key = "questie", label = "if_questie", find = FindQuestie },
        { key = "buffs",   label = "if_buffs",   frame = "BuffFrame" },
        { key = "debuffs", label = "if_debuffs", frame = "DebuffFrame" },
        { key = "bags",    label = "if_bags",    frame = "BagsBar" },
        { key = "micro",   label = "if_micro",   frame = "MicroMenuContainer" },
    },
    defaults = {
        enabled = true,
        linkHover = false,
        modes = {
            chat = "shown", social = "shown", quests = "shown", questie = "shown", buffs = "shown",
            debuffs = "shown", bags = "shown", micro = "shown",
        },
    },
})