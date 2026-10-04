--[[
    Demon Slayer RP - Effets visuels, sons et caméra (réglages client)
    ------------------------------------------------------------------
    Garde-fous de performance appliqués par Client/Systems/Fx/.
]]

Config.Vfx = {
    -- "high" | "medium" | "low" : nombre de couches secondaires (gouttelettes, brume...)
    Quality = "high",

    -- Nombre maximal de particules créées par le gamemode en même temps (au-delà :
    -- les couches secondaires sont ignorées, les couches principales restent)
    MaxActiveParticles = 160,

    -- Au-delà de cette distance (cm) du joueur local, une technique n'est pas dessinée
    MaxDistance = 9000,

    -- Effets de caméra (FOV / recul) : uniquement pour le lanceur, toujours limités
    CameraEffects = true,
    MaxFovDelta = 18,
    MaxArmLengthDelta = 350,
}
