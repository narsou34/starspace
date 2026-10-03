--[[
    Black Clover RP — ui/cl_theme.lua
    Realm : CLIENT

    Thème visuel commun à toutes les interfaces (HUD, menus, grimoire…) :
        - palette de couleurs inspirée de Black Clover ;
        - polices, recréées automatiquement si la résolution change ;
        - BlackClover.Theme.Scale(px) pour adapter les tailles à l'écran.

    Utilisation :
        draw.SimpleText("Texte", "BC.Title", x, y, BlackClover.Theme.Colors.Gold)
]]

BlackClover.Theme = BlackClover.Theme or {}
local Theme = BlackClover.Theme

-- ─── Couleurs ───────────────────────────────────────────────────────────
Theme.Colors = {
    Background  = Color(14, 14, 18, 235),   -- fond des panneaux
    Panel       = Color(26, 24, 30, 240),
    PanelLight  = Color(40, 36, 44, 240),
    Border      = Color(90, 75, 45),

    Gold        = Color(212, 175, 55),      -- dorures des grimoires
    Clover      = Color(46, 160, 87),       -- vert trèfle
    AntiMagic   = Color(30, 30, 30),        -- noir anti-magie
    Parchment   = Color(232, 218, 182),     -- pages du grimoire

    Text        = Color(240, 235, 225),
    TextMuted   = Color(160, 155, 145),

    Health      = Color(200, 50, 50),
    Mana        = Color(70, 140, 255),
    Experience  = Color(230, 190, 60),

    Success     = Color(80, 200, 120),
    Warning     = Color(255, 180, 50),
    Danger      = Color(230, 70, 70),
}

-- ─── Échelle ────────────────────────────────────────────────────────────
-- Les interfaces sont pensées pour 1080p, puis mises à l'échelle.
function Theme.Scale(px)
    return math.max(1, math.Round(px * ScrH() / 1080))
end

-- ─── Polices ────────────────────────────────────────────────────────────
-- Nom → { taille en px (base 1080p), épaisseur }
Theme.Fonts = {
    ["BC.Title"]    = { Size = 36, Weight = 800 },
    ["BC.Subtitle"] = { Size = 26, Weight = 700 },
    ["BC.Body"]     = { Size = 20, Weight = 500 },
    ["BC.Small"]    = { Size = 16, Weight = 500 },
    ["BC.HUD"]      = { Size = 18, Weight = 700 },
}

Theme.FontFace = "Roboto"

function Theme.CreateFonts()
    for name, data in pairs(Theme.Fonts) do
        surface.CreateFont(name, {
            font      = Theme.FontFace,
            size      = Theme.Scale(data.Size),
            weight    = data.Weight,
            antialias = true,
            extended  = true, -- caractères accentués
        })
    end
end

Theme.CreateFonts()

hook.Add("OnScreenSizeChanged", "BlackClover.Theme.Fonts", Theme.CreateFonts)
