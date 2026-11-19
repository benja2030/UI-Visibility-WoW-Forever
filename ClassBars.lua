-- UI Visibility: class bars module
-- Stance, Pet, Possess and Totem bars, using the element engine.
--
-- These are protected action bars: addons can't change their buttons' mouse
-- during combat. Opacity can change at any time, so hiding and hover work
-- in combat; a mouse change made in combat is applied when combat ends.

local ADDON_NAME, ns = ...

ns.AddLocale("en", {
    tab_bars = "Class bars",
    bars_title = "Class Bars",
    bars_stance = "Stance Bar", bars_pet = "Pet Bar", bars_possess = "Possess Bar", bars_totem = "Totem Bar",
    bars_note = "Keybinds always work. Changes made in combat apply when it ends.",
})
ns.AddLocale("es", {
    tab_bars = "Barras clase",
    bars_title = "Barras de clase",
    bars_stance = "Barra de posturas", bars_pet = "Barra de mascota", bars_possess = "Barra de posesión", bars_totem = "Barra de tótems",
    bars_note = "Los atajos siempre funcionan. Los cambios en combate se aplican al terminar.",
})

ns.NewElementsModule({
    key = "bars", titleKey = "bars_title", tabKey = "tab_bars",
    noteKey = "bars_note",
    elements = {
        { key = "stance",  label = "bars_stance",  frame = "StanceBar" },
        { key = "pet",     label = "bars_pet",     frame = "PetActionBar" },
        { key = "possess", label = "bars_possess", frame = "PossessActionBar" },
        { key = "totem",   label = "bars_totem",   frame = "MultiCastActionBarFrame" },
    },
    defaults = {
        enabled = true,
        linkHover = false,
        modes = { stance = "shown", pet = "shown", possess = "shown", totem = "shown" },
    },
})
