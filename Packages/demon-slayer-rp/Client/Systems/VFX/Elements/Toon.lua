--[[
    Demon Slayer RP - Identité "anime" de chaque élément (client)
    ------------------------------------------------------------------
    Textures peintes utilisées pour la FORME PRINCIPALE des techniques
    (voir Core/VFXToon.lua). Les textures sont déjà colorées : Tint reste
    blanc ({1,1,1}) sauf pour les textures neutres (anneaux, spirales,
    étoiles d'impact, bandes de tornade), teintées avec la couleur de l'élément.

      Slash    croissant de coupe (taille, éclat)
      Splash   éclaboussure / explosion face caméra à l'impact
      Star     étoile d'impact (teinte)          Ring   onde au sol (texture + teinte)
      Orb      tête de projectile                 Scatter petits éclats projetés
      Ground   motif au sol des zones             Pillar bandes de tornade / colonne
      Dash     traits laissés le long d'un élan   Tint   teinte des textures neutres
]]

local VFX = DS.VFX

local WHITE = { 1, 1, 1 }

local TOON = {
    water = {
        Slash = "Slash_Water", Splash = "Water_Splash", Star = "Impact_Star", Ring = "Ring_Broken",
        Orb = "Orb_Soft", OrbTint = { 0.45, 0.85, 1.0 }, Scatter = { "Water_Splash" },
        Ground = "Spiral", Pillar = "Swirl_Band", Dash = "Slash_Water", Tint = { 0.35, 0.8, 1.0 }, Glow = 1.5,
        Wave = "Wave_Curl",
    },
    flame = {
        Slash = "Slash_Flame", Splash = "Fire_Ball", Star = "Impact_Star", Ring = "Ring_Broken",
        Orb = "Fire_Ball", Scatter = { "Fire_Tongue" }, Ground = "Ring_Broken", Pillar = "Fire_Tongue",
        Dash = "Fire_Tongue", Tint = { 1.0, 0.55, 0.15 }, Glow = 2.0,
    },
    sun = {
        Slash = "Slash_Sun", Splash = "Fire_Ball", Star = "Impact_Star_Sharp", Ring = "Ring_Shock",
        Orb = "Fire_Ball", Scatter = { "Fire_Tongue" }, Ground = "Sigil", Pillar = "Fire_Tongue",
        Dash = "Fire_Tongue", Tint = { 1.0, 0.75, 0.25 }, Glow = 2.4,
    },
    thunder = {
        Slash = "Slash_Thunder", Splash = "Bolt", Star = "Impact_Star_Sharp", Ring = "Ring_Shock",
        Orb = "Orb_Soft", OrbTint = { 1.0, 0.9, 0.3 }, Scatter = { "Bolt" }, Ground = "Ring_Shock",
        Pillar = "Bolt", Dash = "Bolt", Tint = { 1.0, 0.9, 0.3 }, Glow = 2.6,
    },
    wind = {
        Slash = "Slash_Wind", Splash = "Speed_Lines", Star = "Impact_Star", Ring = "Ring_Broken",
        Orb = "Slash_Wind", Scatter = { "Leaf" }, Ground = "Spiral_Dense", Pillar = "Swirl_Band",
        Dash = "Speed_Lines", Tint = { 0.6, 1.0, 0.75 }, Glow = 1.4,
    },
    mist = {
        Slash = "Slash_Mist", Splash = "Cloud", Star = "Impact_Star", Ring = "Ring_Broken",
        Orb = "Cloud", Scatter = { "Cloud" }, Ground = "Cloud", Pillar = "Cloud",
        Dash = "Cloud", Tint = { 0.85, 0.9, 1.0 }, Glow = 1.0,
    },
    stone = {
        Slash = "Slash_Stone", Splash = "Rock", Star = "Impact_Star", Ring = "Ring_Broken",
        Orb = "Rock", Scatter = { "Rock" }, Ground = "Ring_Broken", Pillar = "Swirl_Band",
        Dash = "Speed_Lines", Tint = { 0.85, 0.75, 0.6 }, Glow = 1.0,
    },
    beast = {
        Slash = "Slash_Beast", Splash = "Impact_Star_Sharp", Star = "Impact_Star_Sharp", Ring = "Ring_Broken",
        Orb = "Slash_Beast", Scatter = { "Rock" }, Ground = "Ring_Broken", Pillar = "Swirl_Band",
        Dash = "Speed_Lines", Tint = { 0.65, 0.8, 1.0 }, Glow = 1.4,
    },
    ice = {
        Slash = "Slash_Ice", Splash = "Ice_Crystal", Star = "Impact_Star_Sharp", Ring = "Ring_Shock",
        Orb = "Ice_Shard", Scatter = { "Ice_Shard", "Ice_Crystal" }, Ground = "Ice_Crystal", Pillar = "Ice_Shard",
        Dash = "Ice_Crystal", Tint = { 0.6, 0.9, 1.0 }, Glow = 1.6,
    },
    shadow = {
        Slash = "Slash_Shadow", Splash = "Ink_Splash", Star = "Impact_Star", Ring = "Ring_Broken",
        Orb = "Ink_Splash", Scatter = { "Ink_Splash" }, Ground = "Spiral_Dense", Pillar = "Swirl_Band",
        Dash = "Ink_Splash", Tint = { 0.6, 0.25, 1.0 }, Glow = 1.3,
    },
    blood = {
        Slash = "Slash_Blood", Splash = "Blood_Splat", Star = "Impact_Star_Sharp", Ring = "Ring_Shock",
        Orb = "Blood_Splat", Scatter = { "Blood_Splat" }, Ground = "Sigil", Pillar = "Swirl_Band",
        Dash = "Blood_Splat", Tint = { 1.0, 0.15, 0.2 }, Glow = 1.8,
    },
    flower = {
        Slash = "Slash_Flower", Splash = "Flower_Bloom", Star = "Impact_Star", Ring = "Ring_Broken",
        Orb = "Flower_Bloom", Scatter = { "Petal" }, Ground = "Flower_Bloom", Pillar = "Swirl_Band",
        Dash = "Petal", Tint = { 1.0, 0.55, 0.8 }, Glow = 1.5,
    },
    sound = {
        Slash = "Slash_Sound", Splash = "Sound_Wave", Star = "Impact_Star_Sharp", Ring = "Ring_Shock",
        Orb = "Orb_Soft", OrbTint = { 1.0, 0.4, 0.9 }, Scatter = { "Impact_Star" }, Ground = "Ring_Shock",
        Pillar = "Swirl_Band", Dash = "Sound_Wave", Tint = { 1.0, 0.45, 0.9 }, Glow = 2.0,
    },
    insect = {
        Slash = "Slash_Insect", Splash = "Butterfly", Star = "Impact_Star", Ring = "Ring_Shock",
        Orb = "Butterfly", Scatter = { "Butterfly" }, Ground = "Flower_Bloom", Pillar = "Swirl_Band",
        Dash = "Butterfly", Tint = { 0.75, 0.6, 1.0 }, Glow = 1.5,
    },
    love = {
        Slash = "Slash_Love", Splash = "Flower_Bloom", Star = "Impact_Star", Ring = "Ring_Shock",
        Orb = "Petal", Scatter = { "Petal" }, Ground = "Flower_Bloom", Pillar = "Swirl_Band",
        Dash = "Petal", Tint = { 1.0, 0.5, 0.75 }, Glow = 1.6,
    },
    serpent = {
        Slash = "Slash_Serpent", Splash = "Impact_Star", Star = "Impact_Star", Ring = "Ring_Broken",
        Orb = "Slash_Serpent", Scatter = { "Impact_Star" }, Ground = "Spiral", Pillar = "Swirl_Band",
        Dash = "Slash_Serpent", Tint = { 0.75, 0.6, 1.0 }, Glow = 1.4,
    },
    neutral = {
        Slash = "Slash_Neutral", Splash = "Impact_Star", Star = "Impact_Star", Ring = "Ring_Shock",
        Orb = "Orb_Soft", Scatter = { "Impact_Star" }, Ground = "Ring_Shock", Pillar = "Swirl_Band",
        Dash = "Speed_Lines", Tint = { 1, 1, 1 }, Glow = 1.4,
    },
}

for id, toon in pairs(TOON) do
    toon.White = WHITE
    VFX.Element(id).Toon = toon
end

--[[
    Pack de particules externe (Asset Pack Unreal / Niagara) : les effets listés
    dans Config.Vfx.CustomPack sont AJOUTÉS comme couches principales de
    l'élément, sans toucher au code. Exemple (Shared/Config/Vfx.lua) :
      CustomPack = {
          water = { Slash = "mon-pack::P_WaterSlash", Impact = "mon-pack::P_WaterHit",
                    Projectile = "mon-pack::P_WaterBall", Zone = "mon-pack::P_Whirlpool", Scale = 1 },
      }
    (l'Asset Pack doit aussi être ajouté à assets_requirements dans Package.toml)
]]
local function layer(asset, scale, life)
    return { Asset = asset, Scale = scale or 1, Life = life or 1.2, Priority = "main" }
end

for id, pack in pairs(Config.Vfx.CustomPack or {}) do
    local element = VFX.Element(id)
    if element and element.Id == id then
        local scale = pack.Scale or 1
        local function push(group, key, asset, life)
            if not asset then return end
            element[group] = element[group] or {}
            element[group][key] = element[group][key] or {}
            table.insert(element[group][key], 1, layer(asset, scale, life))
        end
        push("Slash", "Body", pack.Slash, 1.0)
        push("Impact", "Core", pack.Impact, 1.5)
        push("Projectile", "Core", pack.Projectile, 2.0)
        push("Zone", "Core", pack.Zone, 3.0)
        push("Aura", "Layers", pack.Aura, 2.0)
        if pack.Slash then element.Slash.Body[1].Priority = "main" end
    end
end

--- Identité anime d'un élément (repli : neutre).
function VFX.ToonOf(element)
    return (element and element.Toon) or TOON.neutral
end
