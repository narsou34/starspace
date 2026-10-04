--[[
    Demon Slayer RP - Effets visuels, sons et caméra (réglages client)
    ------------------------------------------------------------------
    Garde-fous de performance appliqués par Client/Systems/VFX/.
]]

Config.Vfx = {
    -- "high" | "medium" | "low" : nombre de couches secondaires (gouttelettes, brume...)
    Quality = "high",

    -- Nombre maximal de particules créées par le gamemode en même temps (plafond strict).
    -- Dégradation progressive : détails coupés à 60 %, couches secondaires à 80 %,
    -- couches principales jusqu'à 100 %.
    MaxActiveParticles = 160,

    -- Quota par technique (même dégradation progressive) : plusieurs joueurs peuvent
    -- lancer leurs ultimes en même temps sans que l'un efface les VFX de l'autre.
    MaxPerTechnique = 100,

    -- Au-delà de cette distance (cm) du joueur local, une technique n'est pas dessinée
    MaxDistance = 9000,

    -- Effets de caméra (FOV / recul) : uniquement pour le lanceur, toujours limités
    CameraEffects = true,
    MaxFovDelta = 18,
    MaxArmLengthDelta = 350,

    -- Formes "anime" : textures peintes (Client/Textures) sur des cartes 3D et des
    -- panneaux face caméra (Client/Systems/VFX/Core/VFXToon.lua)
    Toon = {
        Enabled = true,
        MaxElements = 70,      -- cartes / panneaux affichés en même temps (plafond strict)
        Glow = 1.6,            -- éclat (> 1 = lumineux, bloom)
        -- Si les croissants apparaissent tournés ou à l'envers en jeu : console du jeu
        -- "ds_vfxcalib" (flèche rouge = avant, barre verte = haut) puis ajuster ici.
        UVYaw = 0,             -- rotation de la texture sur la carte (0, 90, 180, -90)
        FlipV = false,         -- inverse le haut et le bas de la texture
    },

    -- Pack de particules externe (Niagara importé avec l'ADK nanos world) : effets
    -- ajoutés par élément. Voir README, section "Packs de particules externes".
    --   water = { Slash = "mon-pack::P_WaterSlash", Impact = "mon-pack::P_WaterHit",
    --             Projectile = "mon-pack::P_WaterBall", Zone = "mon-pack::P_Whirlpool", Scale = 1 },
    CustomPack = {},

    -- Pack Niagara Demon Slayer (DemonSlayerVFX/, construit dans Unreal puis cuit en Asset Pack
    -- "demonslayer-vfx"). Pour l'activer :
    --   1. copier l'Asset Pack cuit dans Server/Assets/demonslayer-vfx/
    --   2. ajouter "demonslayer-vfx" à assets_requirements dans Package.toml
    --   3. Enabled = true ici
    -- Les rôles d'effet (coupe, traînée, impact, projectile, élan, zone, vague, tsunami,
    -- tornade, dragon) jouent alors les NS_VFX_* du pack (table : Config/VfxPackCatalog.lua).
    Pack = {
        Enabled = false,
        Scale = 1,             -- taille globale des systèmes du pack
        Intensity = 1,         -- luminosité globale
    },
}
