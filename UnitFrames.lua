-- UI Visibility: unit frames module
-- Player, pet, target, target of target, focus, party, raid manager and
-- cast bar, using the element engine.
--
-- Unit frames are protected: their mouse can't change in combat, so a change
-- made in combat is applied when combat ends. Opacity changes at any time.

local ADDON_NAME, ns = ...

ns.AddLocale("en", {
    tab_unitframes = "Unit frames",
    uf_title = "Unit Frames",
    uf_player = "Player", uf_pet = "Pet", uf_target = "Target",
    uf_tot = "Target of target", uf_focus = "Focus", uf_party = "Party",
    uf_raid = "Raid manager", uf_castbar = "Cast bar",
    uf_note = "Changes made in combat apply when it ends.",
})
ns.AddLocale("es", {
    tab_unitframes = "Marcos unidad",
    uf_title = "Marcos de unidad",
    uf_player = "Jugador", uf_pet = "Mascota", uf_target = "Objetivo",
    uf_tot = "Objetivo del objetivo", uf_focus = "Foco", uf_party = "Grupo",
    uf_raid = "Administrador de banda", uf_castbar = "Barra de lanzamiento",
    uf_note = "Los cambios en combate se aplican al terminar.",
})

ns.NewElementsModule({
    key = "unitframes", titleKey = "uf_title", tabKey = "tab_unitframes",
    noteKey = "uf_note",
    elements = {
        { key = "player",  label = "uf_player",  frame = "PlayerFrame" },
        { key = "pet",     label = "uf_pet",     frame = "PetFrame" },
        { key = "target",  label = "uf_target",  frame = "TargetFrame" },
        { key = "tot",     label = "uf_tot",     frame = "TargetFrameToT" },
        { key = "focus",   label = "uf_focus",   frame = "FocusFrame" },
        { key = "party",   label = "uf_party",   frame = "PartyFrame" },
        { key = "raid",    label = "uf_raid",    frame = "CompactRaidFrameManager" },
        { key = "castbar", label = "uf_castbar", frame = "PlayerCastingBarFrame" },
    },
    defaults = {
        enabled = true,
        linkHover = false,
        modes = {
            player = "shown", pet = "shown", target = "shown", tot = "shown",
            focus = "shown", party = "shown", raid = "shown", castbar = "shown",
        },
    },
})
