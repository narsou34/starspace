--[[
    Demon Slayer RP - Effets visuels, sons et caméra (réglages client)
    ------------------------------------------------------------------
    Garde-fous de performance appliqués par Client/Systems/Fx/.
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
}
