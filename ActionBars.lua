-- UI Visibility: action bars module
-- Action Bars 1 to 8, using the element engine. Names match Edit Mode:
-- Action Bar 1 is MainActionBar, 2 is MultiBarBottomLeft, and so on.
--
-- These are protected bars: addons can't change their buttons' mouse in
-- combat. Opacity can change at any time; a mouse change made in combat is
-- applied when combat ends.

local ADDON_NAME, ns = ...

ns.AddLocale("en", {
    tab_actionbars = "Action bars",
    ab_title = "Action Bars",
    ab_bar = "Action Bar %d",
    ab_note = "Keybinds always work. Changes made in combat apply when it ends.",
})
ns.AddLocale("es", {
    tab_actionbars = "Barras acción",
    ab_title = "Barras de acción",
    ab_bar = "Barra de acción %d",
    ab_note = "Los atajos siempre funcionan. Los cambios en combate se aplican al terminar.",
})

local BAR_FRAMES = {
    "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight",
    "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7",
}

-- Each label is built from "Action Bar %d" in the current language.
for i = 1, #BAR_FRAMES do
    ns.AddLocale("en", { ["ab_bar" .. i] = string.format(ns.LOCALES.en.ab_bar, i) })
    ns.AddLocale("es", { ["ab_bar" .. i] = string.format(ns.LOCALES.es.ab_bar, i) })
end

local elements, modes = {}, {}
for i, frameName in ipairs(BAR_FRAMES) do
    elements[i] = { key = "bar" .. i, label = "ab_bar" .. i, frame = frameName }
    modes["bar" .. i] = "shown"
end

ns.NewElementsModule({
    key = "actionbars", titleKey = "ab_title", tabKey = "tab_actionbars",
    noteKey = "ab_note",
    elements = elements,
    defaults = { enabled = true, linkHover = false, modes = modes },
})
