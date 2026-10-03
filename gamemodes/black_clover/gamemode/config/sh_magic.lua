--[[
    Black Clover RP — config/sh_magic.lua
    Realm : PARTAGÉ

    Raretés et types de magie.

    ► AJOUTER UNE MAGIE : copiez un bloc, changez l'identifiant (clé) et
      les valeurs, puis ajoutez ses sorts dans config/sh_spells.lua avec
      Magic = "<identifiant>". Rien d'autre à modifier.

    Champs d'une magie :
        Name            nom affiché
        Description     texte du grimoire
        Color           couleur des effets, du grimoire et de l'interface
        Icon            icône (matériau, ex. "icon16/fire.png")
        Rarity          clé de Config.Rarities
        Chance          poids lors du tirage à la cérémonie (0 = jamais tirée)
        RequiredLeaves  (optionnel) nombre minimum de feuilles du grimoire
        Stats           multiplicateurs : Power (dégâts), Mana (mana max), Regen (régénération)
        NoUniversalSpells (optionnel) n'a pas accès aux sorts universels (Magic = "*")
]]

local Config = BlackClover.Config

Config.Rarities = {
    Common    = { Name = "Commune",     Color = Color(190, 190, 190), Order = 1 },
    Uncommon  = { Name = "Peu commune", Color = Color(90, 200, 110),  Order = 2 },
    Rare      = { Name = "Rare",        Color = Color(80, 150, 255),  Order = 3 },
    Epic      = { Name = "Épique",      Color = Color(180, 90, 255),  Order = 4 },
    Legendary = { Name = "Légendaire",  Color = Color(255, 190, 40),  Order = 5 },
}

Config.Magic = {
    fire = {
        Name = "Magie de Feu", Rarity = "Common", Chance = 10,
        Description = "Une magie ardente et destructrice, symbole de passion et de courage.",
        Color = Color(255, 100, 30), Icon = "icon16/fire.png",
        Stats = { Power = 1.15, Mana = 1.0, Regen = 0.95 },
    },
    water = {
        Name = "Magie de l'Eau", Rarity = "Common", Chance = 10,
        Description = "Une magie fluide capable de blesser comme de soigner.",
        Color = Color(60, 150, 255), Icon = "icon16/water.png",
        Stats = { Power = 0.95, Mana = 1.05, Regen = 1.1 },
    },
    wind = {
        Name = "Magie du Vent", Rarity = "Common", Chance = 10,
        Description = "Une magie rapide et tranchante, portée par les courants de mana.",
        Color = Color(150, 240, 180), Icon = "icon16/weather_clouds.png",
        Stats = { Power = 1.0, Mana = 1.0, Regen = 1.05 },
    },
    earth = {
        Name = "Magie de la Terre", Rarity = "Common", Chance = 10,
        Description = "Une magie robuste qui façonne la roche et le sol.",
        Color = Color(160, 115, 60), Icon = "icon16/world.png",
        Stats = { Power = 1.05, Mana = 1.1, Regen = 0.9 },
    },
    smoke = {
        Name = "Magie de Fumée", Rarity = "Common", Chance = 7,
        Description = "Une magie insaisissable qui aveugle et désoriente.",
        Color = Color(150, 150, 160), Icon = "icon16/weather_clouds.png",
        Stats = { Power = 0.9, Mana = 1.0, Regen = 1.1 },
    },
    plant = {
        Name = "Magie Végétale", Rarity = "Common", Chance = 8,
        Description = "Une magie vivante qui fait pousser lianes, fleurs et arbres.",
        Color = Color(80, 200, 70), Icon = "icon16/rosette.png",
        Stats = { Power = 0.95, Mana = 1.1, Regen = 1.05 },
    },
    lightning = {
        Name = "Magie de la Foudre", Rarity = "Uncommon", Chance = 6,
        Description = "Une magie fulgurante, la plus rapide des magies élémentaires.",
        Color = Color(255, 240, 90), Icon = "icon16/lightning.png",
        Stats = { Power = 1.1, Mana = 0.95, Regen = 1.0 },
    },
    steel = {
        Name = "Magie d'Acier", Rarity = "Uncommon", Chance = 6,
        Description = "Une magie solide qui forge lames et armures.",
        Color = Color(180, 190, 200), Icon = "icon16/shield.png",
        Stats = { Power = 1.05, Mana = 1.0, Regen = 0.95 },
    },
    ice = {
        Name = "Magie de Glace", Rarity = "Uncommon", Chance = 6,
        Description = "Une magie glaciale qui ralentit et emprisonne.",
        Color = Color(170, 230, 255), Icon = "icon16/weather_snow.png",
        Stats = { Power = 1.0, Mana = 1.0, Regen = 1.0 },
    },
    poison = {
        Name = "Magie du Poison", Rarity = "Uncommon", Chance = 5,
        Description = "Une magie sournoise qui ronge lentement ses victimes.",
        Color = Color(130, 200, 40), Icon = "icon16/bug.png",
        Stats = { Power = 0.9, Mana = 1.0, Regen = 1.05 },
    },
    thread = {
        Name = "Magie du Fil", Rarity = "Uncommon", Chance = 5,
        Description = "Une magie précise qui lie et manipule les corps.",
        Color = Color(240, 200, 230), Icon = "icon16/link.png",
        Stats = { Power = 0.9, Mana = 1.05, Regen = 1.05 },
    },
    ash = {
        Name = "Magie de Cendre", Rarity = "Uncommon", Chance = 5,
        Description = "Une magie étouffante née des restes de la combustion.",
        Color = Color(120, 105, 100), Icon = "icon16/bomb.png",
        Stats = { Power = 1.05, Mana = 1.0, Regen = 0.95 },
    },
    dark = {
        Name = "Magie des Ténèbres", Rarity = "Rare", Chance = 3,
        Description = "Une magie lourde capable d'absorber et de trancher la magie adverse.",
        Color = Color(110, 50, 170), Icon = "icon16/contrast.png",
        Stats = { Power = 1.2, Mana = 1.1, Regen = 0.9 },
    },
    light = {
        Name = "Magie de Lumière", Rarity = "Rare", Chance = 3,
        Description = "Une magie d'une vitesse absolue, digne d'un capitaine.",
        Color = Color(255, 250, 200), Icon = "icon16/lightbulb.png",
        Stats = { Power = 1.15, Mana = 1.0, Regen = 1.05 },
    },
    spatial = {
        Name = "Magie Spatiale", Rarity = "Rare", Chance = 3,
        Description = "Une magie rarissime qui plie l'espace et ouvre des portails.",
        Color = Color(170, 90, 255), Icon = "icon16/arrow_inout.png",
        Stats = { Power = 0.95, Mana = 1.15, Regen = 1.05 },
    },
    blood = {
        Name = "Magie du Sang", Rarity = "Rare", Chance = 3,
        Description = "Une magie interdite qui puise dans la vie de son utilisateur.",
        Color = Color(180, 10, 30), Icon = "icon16/heart.png",
        Stats = { Power = 1.25, Mana = 0.9, Regen = 0.95 },
    },
    mirror = {
        Name = "Magie du Miroir", Rarity = "Rare", Chance = 3,
        Description = "Une magie de reflets qui protège et dédouble.",
        Color = Color(200, 235, 245), Icon = "icon16/picture.png",
        Stats = { Power = 0.95, Mana = 1.05, Regen = 1.05 },
    },
    dream = {
        Name = "Magie des Rêves", Rarity = "Epic", Chance = 1.5,
        Description = "Une magie onirique qui plonge les ennemis dans le sommeil.",
        Color = Color(255, 170, 220), Icon = "icon16/star.png",
        Stats = { Power = 1.05, Mana = 1.15, Regen = 1.1 },
    },
    gravity = {
        Name = "Magie de Gravité", Rarity = "Epic", Chance = 1.5,
        Description = "Une magie écrasante qui contrôle le poids de toute chose.",
        Color = Color(110, 85, 170), Icon = "icon16/anchor.png",
        Stats = { Power = 1.2, Mana = 1.1, Regen = 1.0 },
    },
    time = {
        Name = "Magie du Temps", Rarity = "Legendary", Chance = 0.5,
        Description = "Une magie légendaire qui ralentit, accélère et arrête le temps.",
        Color = Color(225, 205, 120), Icon = "icon16/clock.png",
        Stats = { Power = 1.1, Mana = 1.25, Regen = 1.15 },
    },
    anti_magic = {
        Name = "Anti-Magie", Rarity = "Legendary", Chance = 0.3,
        RequiredLeaves = 5, NoUniversalSpells = true,
        Description = "L'absence totale de mana. Annule la magie… et ne coûte rien.",
        Color = Color(60, 60, 60), Icon = "icon16/cancel.png",
        Stats = { Power = 1.3, Mana = 0, Regen = 0 },
    },
}
