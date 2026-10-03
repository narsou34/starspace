--[[
    Demon Slayer RP - Security (serveur)
    ------------------------------------------------------------------
    - Limiteur de débit par joueur (token bucket)
    - Score d'infractions avec décroissance et expulsion automatique
    - Statistiques de sécurité

    Utilisé par DS.Net pour chaque évènement reçu, et réutilisable par
    n'importe quel système (ex : DS.Security.Flag(session, "invalid", "...")).
]]

local Security = DS.Module("Security")
DS.Security = Security

local Log = Security.Log
local cfg

local stats = {
    violations = 0,
    kicks = 0,
    byKind = {},
}

function Security:Init()
    cfg = Config.Security

    -- Les bornes de validation partagées prennent les valeurs du serveur
    DS.Validator.Defaults.MaxStringLength = cfg.MaxStringLength
    DS.Validator.Defaults.MaxTableEntries = cfg.MaxTableEntries
    DS.Validator.Defaults.MaxTableDepth = cfg.MaxTableDepth

    Log:Info("Anti-exploit actif : %s evt/s max par joueur, expulsion a %s points",
        cfg.GlobalRate.max * 1000 // cfg.GlobalRate.windowMs, cfg.KickThreshold)
end

--- État de sécurité attaché à chaque session (créé par le PlayerManager).
function Security.CreateState()
    return {
        score = 0,
        total = 0,
        lastViolationAt = 0,
        lastLogAt = {},
    }
end

--- Consomme un jeton du limiteur `key` de la session. false = débit dépassé.
function Security.ConsumeRate(session, key, rate)
    return DS.Utils.ConsumeToken(session.rate, key, rate or cfg.DefaultRate, DS.Utils.NowMs())
end

--- Enregistre une infraction. kind : "rate" | "state" | "invalid" | "unauthorized" | autre.
function Security.Flag(session, kind, detail)
    if session.kicked then return end

    local now = DS.Utils.NowMs()
    local state = session.security

    -- Décroissance du score depuis la dernière infraction
    if state.lastViolationAt > 0 then
        local elapsedSec = (now - state.lastViolationAt) / 1000
        state.score = math.max(0, state.score - elapsedSec * cfg.ViolationDecayPerSecond)
    end
    state.lastViolationAt = now
    state.score = state.score + (cfg.ViolationWeights[kind] or 1)
    state.total = state.total + 1

    stats.violations = stats.violations + 1
    stats.byKind[kind] = (stats.byKind[kind] or 0) + 1

    -- Log limité pour qu'un spam ne puisse pas inonder la console
    local lastLog = state.lastLogAt[kind]
    if not lastLog or now - lastLog >= cfg.LogThrottleMs then
        state.lastLogAt[kind] = now
        Log:Security("%s (#%s, compte %s) - %s : %s | score %.1f/%s",
            session.name, session.id, session.accountId, kind, tostring(detail), state.score, cfg.KickThreshold)
    end

    DS.Bus.Emit("Security:Violation", session, kind, detail, state.score)

    if cfg.KickEnabled and state.score >= cfg.KickThreshold then
        stats.kicks = stats.kicks + 1
        Log:Security("Expulsion de %s (#%s, compte %s) : seuil d'infractions atteint (%s infractions)",
            session.name, session.id, session.accountId, state.total)
        session:Kick(cfg.KickReason)
    end
end

--- Score courant (avec décroissance appliquée), pour affichage.
function Security.GetScore(session)
    local state = session.security
    if state.lastViolationAt == 0 then return 0 end
    local elapsedSec = (DS.Utils.NowMs() - state.lastViolationAt) / 1000
    return math.max(0, state.score - elapsedSec * cfg.ViolationDecayPerSecond)
end

function Security.GetStats()
    return {
        violations = stats.violations,
        kicks = stats.kicks,
        byKind = DS.Utils.DeepCopy(stats.byKind),
    }
end

return Security
