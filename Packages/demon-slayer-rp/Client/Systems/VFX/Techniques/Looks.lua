--[[
    Demon Slayer RP - "Look" de chaque technique (client)
    ------------------------------------------------------------------
    Identité visuelle propre à chaque technique (voir Signatures.lua pour la
    signification des champs). Clé : identifiant du souffle / de l'art, puis
    numéro de l'emplacement (1 = Q, 2 = E, 3 = R, 4 = F, 5 = X, 6 = C).

    Une technique absente reçoit un look par défaut qui dépend de sa touche :
    Q coupe penchée, E coupe montante, R coupe descendante, F diagonale,
    X croissant géant horizontal.
]]

local VFX = DS.VFX

local LOOKS = {
    -- ---------------------------------------------------------------- souffles
    flamme = {
        { Planes = { "flat" }, Scale = 1.2, OnDash = "fire_line" },                                  -- Feu inconnu
        { Planes = { "rising" }, Scale = 1.15 },                                                     -- Ciel ascendant
        { Planes = { "falling" }, Scale = 1.3, OnBurst = "fire_pillar" },                            -- Univers flamboyant
        { Planes = { "diagonal" }, Orb = "Fire_Ball", OrbSize = 300, OnRelease = "tiger_roar" },     -- Tigre flamboyant
        { Planes = { "flat" }, Big = true, OnDash = "inferno" },                                     -- Purgatoire
    },
    tonnerre = {
        { Planes = { "tilted" }, OnDash = "bolt_line" },                                             -- Éclair foudroyant
        { Planes = { "flat", "diagonal", "diagonal2", "tilted", "rising" }, OnRelease = "bolt_ring" }, -- Esprit du riz
        { Planes = { "diagonal", "diagonal2" }, OnDash = "bolt_line" },                              -- Essaim de tonnerre
        { Planes = { "rising" }, Orb = "Bolt", OrbSize = 220, OnBurst = "bolt_rain" },               -- Tonnerre lointain
        { Planes = { "flat" }, Big = true, OnDash = "thunder_god" },                                 -- Honoikazuchi no Kami
    },
    brume = {
        { Planes = { "tilted" }, OnDash = "mist_veil" },
        { Planes = { "flat", "diagonal", "falling", "diagonal2", "rising", "tilted", "flat", "falling" }, Scale = 0.95 },
        { Planes = { "flat" }, OnRelease = "mist_veil", FlatZone = true },
        { Planes = { "tilted" }, OnDash = "mist_veil" },
        { Planes = { "flat" }, Big = true, OnRelease = "mist_dome", FlatZone = true },
    },
    serpent = {
        { Planes = { "tilted" } },
        { Planes = { "diagonal2" } },
        { Planes = { "flat" } },
        { Planes = { "diagonal", "diagonal2" } },
        { Planes = { "flat" }, Big = true },
    },
    vent = {
        { Planes = { "flat" }, OnDash = "tornado" },                                                 -- Tourbillon tranchant
        { Planes = { "diagonal", "diagonal2", "diagonal" }, Multi = 3 },                             -- Griffes purificatrices
        { Planes = { "tilted" }, Orb = "Slash_Wind", OrbSize = 220 },                                -- Vent froid de montagne
        { Planes = { "rising" }, OnRelease = "tornado" },                                            -- Arbre de la tempête
        { Planes = { "flat" }, Big = true, OnRelease = "typhoon" },                                  -- Typhon Idaten
    },
    son = {
        { Planes = { "falling" }, OnBurst = "sound_rings" },                                         -- Rugissement
        { Planes = { "flat", "tilted" }, OnRelease = "sound_rings" },                                -- Tranchants résonnants
        { Planes = { "diagonal" }, OrbSize = 160 },                                                  -- Représentation des cordes
        { Planes = { "rising" }, OnRelease = "score" },                                              -- Partition
        { Planes = { "falling" }, Big = true, OnBurst = "sound_rings" },                             -- Concert explosif
    },
    insecte = {
        { Planes = { "tilted" }, OnDash = "butterflies" },                                           -- Caprice
        { Planes = { "tilted" }, OnRelease = "butterflies" },                                        -- Dard
        { Planes = { "flat", "diagonal", "diagonal2", "flat", "diagonal", "diagonal2" } },           -- Hexagone
        { Planes = { "tilted" }, OnDash = "butterflies" },                                           -- Zigzag
        { Planes = { "flat" }, Big = true, OnRelease = "wisteria" },                                 -- Brume de glycine
    },
    amour = {
        { Planes = { "flat" }, OnDash = "bloom" },
        { Planes = { "rising", "falling" } },
        { Planes = { "tilted" } },
        { Planes = { "diagonal", "diagonal2" }, Multi = 3 },
        { Planes = { "flat" }, Big = true, OnRelease = "petal_storm" },
    },
    -- Souffles instantanés
    pierre = {
        { Planes = { "tilted" }, OnRelease = "rocks" },
        { Planes = { "rising" }, OnRelease = "rocks" },
        { Planes = { "flat" } },
        { Planes = { "falling" }, OnRelease = "rocks" },
        { Planes = { "flat" }, Big = true, OnRelease = "rocks" },
    },
    fleur = {
        { Planes = { "tilted" }, OnRelease = "bloom" },
        { Planes = { "flat" }, OnRelease = "bloom" },
        { Planes = { "rising" } },
        { Planes = { "flat" }, OnRelease = "petal_storm" },
        { Planes = { "flat" }, Big = true, OnRelease = "bloom" },
    },
    bete = {
        { Planes = { "tilted" }, Multi = 2 },
        { Planes = { "diagonal", "diagonal2" }, Multi = 2 },
        { Planes = { "falling" }, Multi = 2 },
        { Planes = { "flat" }, Multi = 3 },
        { Planes = { "tilted" }, Multi = 2 },
    },
    soleil = {
        { Planes = { "rising" }, OnRelease = "sun_seal" },
        { Planes = { "flat" }, Scale = 1.2 },
        { Planes = { "falling" }, OnRelease = "fire_pillar" },
        { Planes = { "tilted" } },
        { Planes = { "flat" }, Big = true, OnRelease = "sun_seal" },
    },
    -- ------------------------------------------------------- arts démoniaques
    glace = {
        { Planes = { "flat", "tilted" }, OnRelease = "ice_spikes" },                                 -- Éventails de glace
        { Planes = { "flat" }, OnRelease = "mist_veil", FlatZone = true },                           -- Nuages gelants
        { Planes = { "tilted" }, Orb = "Ice_Shard", OrbSize = 170 },                                 -- Lances de glace
        { Planes = { "falling" }, OnBurst = "ice_spikes" },                                          -- Hiver glacé
        { Planes = { "flat" }, Big = true, OnRelease = "ice_bodhisattva" },                          -- Bodhisattva
    },
    sang = {
        { Planes = { "diagonal", "diagonal2" }, Multi = 3 },                                         -- Griffes
        { Planes = { "flat" }, Orb = "Slash_Blood", OrbSize = 170 },                                 -- Lames de sang
        { Planes = { "falling" }, OnBurst = "blood_burst" },                                         -- Explosion de sang
        { Planes = { "falling" }, OnDash = "blood_burst" },                                          -- Bond féroce
        { Planes = { "flat" }, Big = true, OnRelease = "blood_awakening" },                          -- Éveil du sang
    },
    ombre = {
        { Planes = { "diagonal", "diagonal2" }, Multi = 3 },
        { Planes = { "tilted" }, OnDash = "ink_veil" },
        { Planes = { "flat" } },
        { Planes = { "rising" }, Orb = "Ink_Splash", OrbSize = 260 },
        { Planes = { "flat" }, Big = true, OnRelease = "eternal_night" },
    },
    fleurs = {
        { Planes = { "flat", "tilted", "rising" }, OnRelease = "bloom" },
        { Planes = { "tilted" } },
        { Planes = { "falling" }, OnBurst = "bloom" },
        { Planes = { "flat" }, OnRelease = "petal_storm" },
        { Planes = { "flat" }, Big = true, OnBurst = "bloom" },
    },
    temari = {
        { Planes = { "diagonal", "diagonal2" }, Multi = 2 },
        { Planes = { "tilted" }, OnRelease = "blood_burst" },
        { Planes = { "rising" } },
        { Planes = { "falling" } },
        { Planes = { "flat" }, Big = true },
    },
    fils = {
        { Planes = { "flat" }, Scale = 1.3 },
        { Planes = { "tilted" }, Multi = 3 },
        { Planes = { "flat", "rising" }, Multi = 3 },
        { Planes = { "diagonal" } },
        { Planes = { "flat" }, Big = true, Multi = 3 },
    },
    biwa = {
        { Planes = { "diagonal", "diagonal2" }, Multi = 2 },
        { Planes = { "tilted" }, OnRelease = "ink_veil" },
        { Planes = { "falling" }, OnRelease = "sound_rings" },
        { Planes = { "rising" } },
        { Planes = { "flat" }, Big = true, OnRelease = "eternal_night" },
    },
    reve = {
        { Planes = { "diagonal", "diagonal2" }, Multi = 2 },
        { Planes = { "tilted" }, OnRelease = "mist_veil" },
        { Planes = { "falling" }, OnRelease = "ink_veil" },
        { Planes = { "rising" } },
        { Planes = { "flat" }, Big = true, OnRelease = "mist_dome" },
    },
}

local DEFAULT_BY_SLOT = {
    { Planes = { "tilted" } }, { Planes = { "rising" } }, { Planes = { "falling" } },
    { Planes = { "diagonal" } }, { Planes = { "flat" }, Big = true }, { Planes = { "flat" }, Big = true },
}

--- Look d'une technique (jamais nil).
function VFX.LookOf(tech)
    if not tech then return DEFAULT_BY_SLOT[1] end
    local set = LOOKS[tech.SetId]
    return (set and set[tech.Slot]) or tech.Look or DEFAULT_BY_SLOT[tech.Slot] or DEFAULT_BY_SLOT[1]
end

--- Orientation du croissant pour le n-ième coup d'une technique.
function VFX.PlaneOf(look, index)
    local planes = look.Planes
    if not planes or #planes == 0 then return nil end
    return planes[((index or 1) - 1) % #planes + 1]
end

VFX.Looks = LOOKS
