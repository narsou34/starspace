--[[
    Black Clover RP — config/sh_spells.lua
    Realm : PARTAGÉ

    Réglages de combat et liste des sorts.

    ► AJOUTER UN SORT : ajoutez une entrée dans Config.Spells.
      La clé (ex. "fire_ball") est l'identifiant sauvegardé en base :
      ne la changez plus une fois le serveur en production.

    Champs communs :
        Name, Description
        Magic            identifiant de magie ("*" = sort universel)
        Type             projectile | explosion | zone | melee | defense | buff |
                         debuff | movement | summon | heal | control
        ManaCost         coût en mana
        HealthCost       (optionnel) coût en PV (magie du sang)
        Cooldown         secondes
        LevelRequired    niveau du personnage requis
        GrimoireLevelRequired (optionnel) niveau de maîtrise du grimoire requis
        Requirements     (optionnel) { Quest = "id", Rank = "id" } — vérifiés par
                         le hook "BlackClover.CheckSpellRequirement" (quêtes/rangs à venir)
        Damage           dégâts de base (avant bonus)
        Range            portée en unités (≈ 1 unité = 1,9 cm)
        Status           (optionnel) effet appliqué (cible, ou lanceur pour buff/defense)
        LifeSteal        (optionnel) part des dégâts rendue en PV au lanceur
        Sound            (optionnel) son au lancement
        Effect           (optionnel) { Scale = 1 } taille des effets visuels

    Champs selon le type :
        projectile  Speed, Radius (0 = cible unique), Count, Spread, Size
        explosion   Radius
        zone        Radius, Duration, TickRate (Damage = par tick)
        melee       Cone (0 à 1, plus petit = plus large), Knockback
        movement    Mode ("dash" ou "teleport"), Force (dash)
        summon      Duration, FireRate, Speed
        heal        Heal, Radius (0 = soi uniquement)
        debuff / control : visent le joueur/PNJ regardé (Range)
]]

local Config = BlackClover.Config

Config.Combat = {
    GlobalCooldown = 0.35,   -- délai minimum entre deux sorts, tous sorts confondus
    AllowPvP       = true,   -- les sorts blessent les autres joueurs
    DamageNPCs     = true,   -- les sorts blessent les PNJ
    DamageProps    = true,   -- les sorts endommagent les objets cassables
    MaxSpellDamage = 1000,   -- plafond de sécurité par coup
}

-- ─── Effets de statut réutilisables ─────────────────────────────────────
-- Champs : ID, Name, Duration, SpeedMult, DamageTakenMult, DamageDealtMult,
--          ManaRegenMult, MaxManaMult, Rooted, Silenced, DamagePerSecond
local function Slow(mult, duration)
    return { ID = "slow", Name = "Ralenti", Duration = duration, SpeedMult = mult }
end

local function Root(duration, name)
    return { ID = "root", Name = name or "Immobilisé", Duration = duration, Rooted = true }
end

local function Poison(dps, duration)
    return { ID = "poison", Name = "Empoisonné", Duration = duration, DamagePerSecond = dps }
end

local function Shield(reduction, duration, name)
    return { ID = "shield", Name = name or "Protégé", Duration = duration, DamageTakenMult = 1 - reduction }
end

Config.Spells = {
    -- ═══ Universel ════════════════════════════════════════════════════
    mana_skin = {
        Name = "Peau de mana", Magic = "*", Type = "defense",
        Description = "Recouvre le corps d'une fine couche de mana qui amortit les coups.",
        ManaCost = 20, Cooldown = 20, LevelRequired = 3, Range = 0, Damage = 0,
        Status = Shield(0.25, 6, "Peau de mana"),
    },

    -- ═══ Feu ══════════════════════════════════════════════════════════
    fire_ball = {
        Name = "Boule de feu", Magic = "fire", Type = "projectile",
        Description = "Une sphère de flammes lancée à grande vitesse.",
        ManaCost = 12, Cooldown = 1.2, LevelRequired = 1, Damage = 18, Range = 2500,
        Speed = 1500, Radius = 0, Size = 20,
    },
    fire_explosion = {
        Name = "Explosion de flammes", Magic = "fire", Type = "explosion",
        Description = "Fait exploser l'air à l'endroit visé.",
        ManaCost = 30, Cooldown = 6, LevelRequired = 5, Damage = 35, Range = 1500, Radius = 220,
    },
    fire_lion = {
        Name = "Rugissement du lion flamboyant", Magic = "fire", Type = "projectile",
        Description = "Un lion de flammes qui dévaste tout sur son passage.",
        ManaCost = 55, Cooldown = 14, LevelRequired = 15, GrimoireLevelRequired = 5,
        Damage = 60, Range = 3000, Speed = 900, Radius = 260, Size = 60,
    },

    -- ═══ Eau ══════════════════════════════════════════════════════════
    water_bullet = {
        Name = "Balle d'eau", Magic = "water", Type = "projectile",
        Description = "Un projectile d'eau compressée.",
        ManaCost = 10, Cooldown = 1, LevelRequired = 1, Damage = 14, Range = 2500, Speed = 1700, Size = 16,
    },
    water_heal = {
        Name = "Bénédiction de la déesse", Magic = "water", Type = "heal",
        Description = "Une eau bienfaisante qui soigne le lanceur et ses alliés proches.",
        ManaCost = 35, Cooldown = 12, LevelRequired = 5, Damage = 0, Range = 0, Heal = 30, Radius = 250,
    },
    water_dragon = {
        Name = "Dragon d'eau", Magic = "water", Type = "projectile",
        Description = "Un dragon d'eau furieux qui s'abat sur l'ennemi.",
        ManaCost = 50, Cooldown = 12, LevelRequired = 15, GrimoireLevelRequired = 5,
        Damage = 50, Range = 3000, Speed = 1100, Radius = 200, Size = 50,
    },

    -- ═══ Vent ═════════════════════════════════════════════════════════
    wind_blade = {
        Name = "Lames de vent", Magic = "wind", Type = "projectile",
        Description = "Trois lames d'air tranchantes.",
        ManaCost = 14, Cooldown = 1.5, LevelRequired = 1, Damage = 8, Range = 2200,
        Speed = 2200, Count = 3, Spread = 5, Size = 14,
    },
    wind_dash = {
        Name = "Pas du vent", Magic = "wind", Type = "movement",
        Description = "Le vent propulse le lanceur dans la direction regardée.",
        ManaCost = 15, Cooldown = 4, LevelRequired = 3, Damage = 0, Range = 0, Mode = "dash", Force = 900,
    },
    wind_tornado = {
        Name = "Tornade sacrée", Magic = "wind", Type = "zone",
        Description = "Une tornade qui happe et ralentit les ennemis.",
        ManaCost = 45, Cooldown = 15, LevelRequired = 12, Damage = 6, Range = 1500,
        Radius = 220, Duration = 5, TickRate = 0.5, Status = Slow(0.5, 1),
    },

    -- ═══ Terre ════════════════════════════════════════════════════════
    earth_spike = {
        Name = "Pic de terre", Magic = "earth", Type = "explosion",
        Description = "Un pic de roche jaillit du sol.",
        ManaCost = 14, Cooldown = 2, LevelRequired = 1, Damage = 22, Range = 1200, Radius = 110,
    },
    earth_wall = {
        Name = "Rempart de pierre", Magic = "earth", Type = "defense",
        Description = "Une armure de pierre réduit fortement les dégâts reçus.",
        ManaCost = 30, Cooldown = 18, LevelRequired = 4, Damage = 0, Range = 0,
        Status = Shield(0.5, 6, "Rempart de pierre"),
    },
    earth_quake = {
        Name = "Séisme", Magic = "earth", Type = "zone",
        Description = "Le sol tremble violemment dans une large zone.",
        ManaCost = 50, Cooldown = 16, LevelRequired = 14, Damage = 8, Range = 1500,
        Radius = 350, Duration = 4, TickRate = 1, Status = Slow(0.6, 1.2),
    },

    -- ═══ Foudre ═══════════════════════════════════════════════════════
    lightning_bolt = {
        Name = "Éclair", Magic = "lightning", Type = "projectile",
        Description = "Un trait de foudre presque instantané.",
        ManaCost = 13, Cooldown = 1.3, LevelRequired = 1, Damage = 20, Range = 3000, Speed = 4500, Size = 14,
    },
    lightning_speed = {
        Name = "Vitesse de la foudre", Magic = "lightning", Type = "buff",
        Description = "La foudre parcourt le corps et décuple la vitesse.",
        ManaCost = 25, Cooldown = 18, LevelRequired = 5, Damage = 0, Range = 0,
        Status = { ID = "haste", Name = "Vitesse de la foudre", Duration = 6, SpeedMult = 1.6 },
    },
    lightning_judgment = {
        Name = "Jugement de la foudre", Magic = "lightning", Type = "explosion",
        Description = "La foudre s'abat et paralyse brièvement les cibles.",
        ManaCost = 55, Cooldown = 15, LevelRequired = 15, GrimoireLevelRequired = 5,
        Damage = 50, Range = 2000, Radius = 200, Status = Root(1, "Paralysé"),
    },

    -- ═══ Ténèbres ═════════════════════════════════════════════════════
    dark_orb = {
        Name = "Orbe des ténèbres", Magic = "dark", Type = "projectile",
        Description = "Une sphère d'obscurité dense.",
        ManaCost = 14, Cooldown = 1.4, LevelRequired = 1, Damage = 22, Range = 2200, Speed = 1300, Size = 24,
    },
    dark_cloak = {
        Name = "Manteau des ténèbres", Magic = "dark", Type = "defense",
        Description = "Les ténèbres enveloppent le lanceur et absorbent les attaques.",
        ManaCost = 35, Cooldown = 20, LevelRequired = 6, Damage = 0, Range = 0,
        Status = Shield(0.6, 5, "Manteau des ténèbres"),
    },
    dark_slash = {
        Name = "Tranchant dimensionnel", Magic = "dark", Type = "melee",
        Description = "Une entaille d'obscurité qui fend l'espace devant soi.",
        ManaCost = 60, Cooldown = 14, LevelRequired = 15, GrimoireLevelRequired = 5,
        Damage = 70, Range = 260, Cone = 0.5, Knockback = 400,
    },

    -- ═══ Lumière ══════════════════════════════════════════════════════
    light_swords = {
        Name = "Épées de lumière", Magic = "light", Type = "projectile",
        Description = "Trois épées de lumière filent à une vitesse aveuglante.",
        ManaCost = 15, Cooldown = 1.5, LevelRequired = 1, Damage = 9, Range = 3000,
        Speed = 5000, Count = 3, Spread = 3, Size = 14,
    },
    light_step = {
        Name = "Pas de lumière", Magic = "light", Type = "movement",
        Description = "Se déplace instantanément à l'endroit regardé.",
        ManaCost = 25, Cooldown = 6, LevelRequired = 6, Damage = 0, Range = 800, Mode = "teleport",
    },
    light_judgment = {
        Name = "Jugement de la lumière", Magic = "light", Type = "explosion",
        Description = "Une colonne de lumière purificatrice.",
        ManaCost = 60, Cooldown = 16, LevelRequired = 16, GrimoireLevelRequired = 5,
        Damage = 60, Range = 2000, Radius = 280,
    },

    -- ═══ Espace ═══════════════════════════════════════════════════════
    spatial_rift = {
        Name = "Faille spatiale", Magic = "spatial", Type = "projectile",
        Description = "Une fissure dans l'espace qui déchire la cible.",
        ManaCost = 13, Cooldown = 1.3, LevelRequired = 1, Damage = 16, Range = 2200, Speed = 1800, Size = 18,
    },
    spatial_portal = {
        Name = "Portail", Magic = "spatial", Type = "movement",
        Description = "Ouvre un portail et traverse instantanément l'espace.",
        ManaCost = 25, Cooldown = 5, LevelRequired = 4, Damage = 0, Range = 1200, Mode = "teleport",
    },
    spatial_crush = {
        Name = "Compression spatiale", Magic = "spatial", Type = "control",
        Description = "Comprime l'espace autour de la cible, qui ne peut plus bouger.",
        ManaCost = 40, Cooldown = 14, LevelRequired = 12, Damage = 20, Range = 1200, Status = Root(3),
    },

    -- ═══ Plante ═══════════════════════════════════════════════════════
    plant_vines = {
        Name = "Lianes entravantes", Magic = "plant", Type = "control",
        Description = "Des lianes jaillissent et ligotent la cible.",
        ManaCost = 15, Cooldown = 6, LevelRequired = 1, Damage = 8, Range = 1200, Status = Root(2.5, "Ligoté"),
    },
    plant_bloom = {
        Name = "Fleur de guérison", Magic = "plant", Type = "heal",
        Description = "Une fleur éclot et soigne les personnes proches.",
        ManaCost = 30, Cooldown = 12, LevelRequired = 5, Damage = 0, Range = 0, Heal = 25, Radius = 200,
    },
    plant_tree = {
        Name = "Arbre de mana", Magic = "plant", Type = "summon",
        Description = "Invoque un arbre magique qui attaque les ennemis proches.",
        ManaCost = 50, Cooldown = 25, LevelRequired = 14, Damage = 10, Range = 1200,
        Duration = 15, FireRate = 1.2, Speed = 1400,
    },

    -- ═══ Acier ════════════════════════════════════════════════════════
    steel_spear = {
        Name = "Lance d'acier", Magic = "steel", Type = "projectile",
        Description = "Une lance d'acier forgée par la magie.",
        ManaCost = 13, Cooldown = 1.3, LevelRequired = 1, Damage = 20, Range = 2200, Speed = 2000, Size = 14,
    },
    steel_armor = {
        Name = "Armure d'acier", Magic = "steel", Type = "defense",
        Description = "Une armure de métal recouvre le corps.",
        ManaCost = 30, Cooldown = 18, LevelRequired = 5, Damage = 0, Range = 0,
        Status = Shield(0.55, 8, "Armure d'acier"),
    },
    steel_rain = {
        Name = "Pluie de lames", Magic = "steel", Type = "explosion",
        Description = "Des dizaines de lames tombent du ciel.",
        ManaCost = 50, Cooldown = 14, LevelRequired = 14, Damage = 40, Range = 1800, Radius = 250,
    },

    -- ═══ Glace ════════════════════════════════════════════════════════
    ice_shard = {
        Name = "Éclat de glace", Magic = "ice", Type = "projectile",
        Description = "Un éclat gelé qui ralentit la cible.",
        ManaCost = 12, Cooldown = 1.3, LevelRequired = 1, Damage = 14, Range = 2200, Speed = 1800, Size = 16,
        Status = Slow(0.6, 2),
    },
    ice_prison = {
        Name = "Prison de glace", Magic = "ice", Type = "control",
        Description = "Enferme la cible dans un bloc de glace.",
        ManaCost = 35, Cooldown = 14, LevelRequired = 6, Damage = 10, Range = 1000, Status = Root(3, "Gelé"),
    },
    ice_storm = {
        Name = "Blizzard", Magic = "ice", Type = "zone",
        Description = "Une tempête de glace gèle tout dans la zone.",
        ManaCost = 50, Cooldown = 16, LevelRequired = 14, Damage = 5, Range = 1500,
        Radius = 280, Duration = 6, TickRate = 0.5, Status = Slow(0.4, 1),
    },

    -- ═══ Sang ═════════════════════════════════════════════════════════
    blood_lance = {
        Name = "Lance de sang", Magic = "blood", Type = "projectile",
        Description = "Une lance formée du sang du lanceur.",
        ManaCost = 8, HealthCost = 4, Cooldown = 1.2, LevelRequired = 1, Damage = 24, Range = 2200, Speed = 1900, Size = 16,
    },
    blood_frenzy = {
        Name = "Frénésie sanguine", Magic = "blood", Type = "buff",
        Description = "Sacrifie du sang pour décupler sa puissance.",
        ManaCost = 15, HealthCost = 15, Cooldown = 20, LevelRequired = 6, Damage = 0, Range = 0,
        Status = { ID = "frenzy", Name = "Frénésie", Duration = 8, DamageDealtMult = 1.3 },
    },
    blood_drain = {
        Name = "Drain vital", Magic = "blood", Type = "debuff",
        Description = "Aspire la vie de la cible et affaiblit ses attaques.",
        ManaCost = 40, Cooldown = 14, LevelRequired = 14, Damage = 30, Range = 900, LifeSteal = 0.5,
        Status = { ID = "weakened", Name = "Affaibli", Duration = 6, DamageDealtMult = 0.8 },
    },

    -- ═══ Poison ═══════════════════════════════════════════════════════
    poison_dart = {
        Name = "Dard empoisonné", Magic = "poison", Type = "projectile",
        Description = "Un dard qui empoisonne la cible.",
        ManaCost = 12, Cooldown = 1.5, LevelRequired = 1, Damage = 8, Range = 2200, Speed = 2000, Size = 12,
        Status = Poison(3, 5),
    },
    poison_cloud = {
        Name = "Nuage toxique", Magic = "poison", Type = "zone",
        Description = "Un nuage de poison stagne dans la zone.",
        ManaCost = 35, Cooldown = 14, LevelRequired = 6, Damage = 4, Range = 1400,
        Radius = 240, Duration = 6, TickRate = 0.5,
    },
    poison_toxin = {
        Name = "Toxine débilitante", Magic = "poison", Type = "debuff",
        Description = "Une toxine qui ronge la cible et réduit sa force.",
        ManaCost = 40, Cooldown = 15, LevelRequired = 12, Damage = 10, Range = 1000,
        Status = { ID = "toxin", Name = "Intoxiqué", Duration = 6, DamageDealtMult = 0.7, DamagePerSecond = 3 },
    },

    -- ═══ Fil ══════════════════════════════════════════════════════════
    thread_needles = {
        Name = "Aiguilles de fil", Magic = "thread", Type = "projectile",
        Description = "Une salve d'aiguilles de fil.",
        ManaCost = 13, Cooldown = 1.5, LevelRequired = 1, Damage = 6, Range = 2000,
        Speed = 2400, Count = 4, Spread = 6, Size = 10,
    },
    thread_bind = {
        Name = "Fils de contrôle", Magic = "thread", Type = "control",
        Description = "Des fils invisibles ligotent la cible.",
        ManaCost = 25, Cooldown = 10, LevelRequired = 5, Damage = 5, Range = 1000, Status = Root(2, "Ligoté"),
    },
    thread_puppet = {
        Name = "Marionnettiste", Magic = "thread", Type = "debuff",
        Description = "Prend partiellement le contrôle des mouvements de la cible.",
        ManaCost = 45, Cooldown = 16, LevelRequired = 13, Damage = 0, Range = 1000,
        Status = { ID = "puppet", Name = "Manipulé", Duration = 6, SpeedMult = 0.5, DamageDealtMult = 0.75 },
    },

    -- ═══ Miroir ═══════════════════════════════════════════════════════
    mirror_shard = {
        Name = "Éclat de miroir", Magic = "mirror", Type = "projectile",
        Description = "Un éclat de verre magique tranchant.",
        ManaCost = 12, Cooldown = 1.2, LevelRequired = 1, Damage = 15, Range = 2200, Speed = 2000, Size = 14,
    },
    mirror_reflect = {
        Name = "Miroir protecteur", Magic = "mirror", Type = "defense",
        Description = "Un miroir dévie la majorité des attaques.",
        ManaCost = 35, Cooldown = 20, LevelRequired = 6, Damage = 0, Range = 0,
        Status = Shield(0.7, 4, "Miroir protecteur"),
    },
    mirror_clone = {
        Name = "Reflet combattant", Magic = "mirror", Type = "summon",
        Description = "Invoque un reflet qui attaque les ennemis.",
        ManaCost = 50, Cooldown = 25, LevelRequired = 14, Damage = 12, Range = 1200,
        Duration = 12, FireRate = 1, Speed = 1800,
    },

    -- ═══ Fumée ════════════════════════════════════════════════════════
    smoke_bullet = {
        Name = "Balle de fumée", Magic = "smoke", Type = "projectile",
        Description = "Une boule de fumée compacte.",
        ManaCost = 11, Cooldown = 1.2, LevelRequired = 1, Damage = 13, Range = 2000, Speed = 1500, Size = 22,
    },
    smoke_screen = {
        Name = "Écran de fumée", Magic = "smoke", Type = "zone",
        Description = "Une épaisse fumée ralentit tous ceux qui s'y trouvent.",
        ManaCost = 25, Cooldown = 14, LevelRequired = 4, Damage = 0, Range = 1200,
        Radius = 260, Duration = 6, TickRate = 0.5, Status = Slow(0.6, 1),
    },
    smoke_vanish = {
        Name = "Évanescence", Magic = "smoke", Type = "movement",
        Description = "Le corps se change en fumée et file vers l'avant.",
        ManaCost = 20, Cooldown = 5, LevelRequired = 10, Damage = 0, Range = 0, Mode = "dash", Force = 1100,
    },

    -- ═══ Cendre ═══════════════════════════════════════════════════════
    ash_bullet = {
        Name = "Projectile de cendre", Magic = "ash", Type = "projectile",
        Description = "Un amas de cendres brûlantes.",
        ManaCost = 12, Cooldown = 1.3, LevelRequired = 1, Damage = 16, Range = 2000, Speed = 1500, Size = 20,
    },
    ash_cannon = {
        Name = "Canon de cendre", Magic = "ash", Type = "explosion",
        Description = "Une détonation de cendres compressées.",
        ManaCost = 30, Cooldown = 7, LevelRequired = 6, Damage = 36, Range = 1500, Radius = 200,
    },
    ash_storm = {
        Name = "Tempête de cendres", Magic = "ash", Type = "zone",
        Description = "Une tempête de cendres étouffantes.",
        ManaCost = 45, Cooldown = 15, LevelRequired = 14, Damage = 7, Range = 1500,
        Radius = 260, Duration = 5, TickRate = 0.5,
    },

    -- ═══ Rêve ═════════════════════════════════════════════════════════
    dream_lullaby = {
        Name = "Berceuse", Magic = "dream", Type = "control",
        Description = "Plonge la cible dans un sommeil profond.",
        ManaCost = 18, Cooldown = 8, LevelRequired = 1, Damage = 0, Range = 900, Status = Root(2.5, "Endormi"),
    },
    dream_illusion = {
        Name = "Illusion onirique", Magic = "dream", Type = "debuff",
        Description = "La cible perd ses repères et sa force.",
        ManaCost = 30, Cooldown = 12, LevelRequired = 6, Damage = 8, Range = 1000,
        Status = { ID = "illusion", Name = "Désorienté", Duration = 6, SpeedMult = 0.6, DamageDealtMult = 0.7 },
    },
    dream_nightmare = {
        Name = "Cauchemar", Magic = "dream", Type = "explosion",
        Description = "Un cauchemar éclate et paralyse les esprits.",
        ManaCost = 55, Cooldown = 16, LevelRequired = 15, GrimoireLevelRequired = 5,
        Damage = 45, Range = 1500, Radius = 250, Status = Root(1.5, "Terrifié"),
    },

    -- ═══ Temps ════════════════════════════════════════════════════════
    time_slow = {
        Name = "Ralentissement temporel", Magic = "time", Type = "debuff",
        Description = "Le temps s'écoule plus lentement pour la cible.",
        ManaCost = 18, Cooldown = 8, LevelRequired = 1, Damage = 5, Range = 1200, Status = Slow(0.4, 4),
    },
    time_haste = {
        Name = "Accélération", Magic = "time", Type = "buff",
        Description = "Accélère son propre temps : plus rapide, mana plus vif.",
        ManaCost = 30, Cooldown = 20, LevelRequired = 6, Damage = 0, Range = 0,
        Status = { ID = "haste", Name = "Accéléré", Duration = 7, SpeedMult = 1.5, ManaRegenMult = 1.5 },
    },
    time_stop = {
        Name = "Arrêt du temps", Magic = "time", Type = "zone",
        Description = "Fige le temps dans une zone : personne ne peut bouger.",
        ManaCost = 70, Cooldown = 30, LevelRequired = 18, GrimoireLevelRequired = 8,
        Damage = 0, Range = 1200, Radius = 300, Duration = 3, TickRate = 0.25, Status = Root(0.5, "Figé"),
    },

    -- ═══ Gravité ══════════════════════════════════════════════════════
    gravity_orb = {
        Name = "Sphère de gravité", Magic = "gravity", Type = "projectile",
        Description = "Une sphère dense qui alourdit la cible.",
        ManaCost = 14, Cooldown = 1.5, LevelRequired = 1, Damage = 16, Range = 2000, Speed = 1200, Size = 24,
        Status = Slow(0.6, 2),
    },
    gravity_crush = {
        Name = "Pression gravitationnelle", Magic = "gravity", Type = "control",
        Description = "Écrase la cible au sol sous son propre poids.",
        ManaCost = 30, Cooldown = 10, LevelRequired = 6, Damage = 25, Range = 1000, Status = Root(2, "Écrasé"),
    },
    gravity_well = {
        Name = "Puits gravitationnel", Magic = "gravity", Type = "zone",
        Description = "Une zone de gravité extrême broie tout ce qui s'y trouve.",
        ManaCost = 55, Cooldown = 18, LevelRequired = 15, Damage = 8, Range = 1500,
        Radius = 280, Duration = 5, TickRate = 0.5, Status = Slow(0.3, 1),
    },

    -- ═══ Anti-Magie ═══════════════════════════════════════════════════
    anti_slash = {
        Name = "Taille anti-magie", Magic = "anti_magic", Type = "melee",
        Description = "Un coup d'épée démoniaque qui annule la magie.",
        ManaCost = 0, Cooldown = 0.8, LevelRequired = 1, Damage = 30, Range = 160, Cone = 0.6, Knockback = 250,
    },
    anti_leap = {
        Name = "Bond anti-magique", Magic = "anti_magic", Type = "movement",
        Description = "Un bond surhumain porté par la force physique.",
        ManaCost = 0, Cooldown = 3, LevelRequired = 3, Damage = 0, Range = 0, Mode = "dash", Force = 1000,
    },
    anti_wave = {
        Name = "Onde anti-magie", Magic = "anti_magic", Type = "projectile",
        Description = "Une onde noire qui empêche la cible d'utiliser la magie.",
        ManaCost = 0, Cooldown = 8, LevelRequired = 12, Damage = 40, Range = 2000, Speed = 1600, Radius = 150, Size = 40,
        Status = { ID = "silence", Name = "Magie annulée", Duration = 2.5, Silenced = true },
    },
}
