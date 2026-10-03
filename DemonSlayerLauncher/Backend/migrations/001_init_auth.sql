-- ════════════════════════════════════════════════════════════
--  Demon Slayer RP — Phase 1 : comptes, sessions, sécurité
-- ════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ── Comptes ─────────────────────────────────────────────────
-- Les ID joueurs commencent à 10000 (affichés dans le launcher).
CREATE TABLE users (
  id                   BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 10000) PRIMARY KEY,
  username             VARCHAR(20)  NOT NULL,
  email                VARCHAR(254) NOT NULL,
  password_hash        TEXT         NOT NULL,
  role                 VARCHAR(20)  NOT NULL DEFAULT 'player'
                         CHECK (role IN ('player', 'helper', 'moderator', 'admin', 'superadmin')),
  status               VARCHAR(20)  NOT NULL DEFAULT 'active'
                         CHECK (status IN ('active', 'suspended', 'banned')),
  avatar_url           TEXT,
  password_changed_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  last_login_at        TIMESTAMPTZ,
  created_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX users_username_lower_uq ON users (lower(username));
CREATE UNIQUE INDEX users_email_lower_uq    ON users (lower(email));
CREATE TRIGGER users_set_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── Sessions (refresh tokens) ───────────────────────────────
-- Seul le hash SHA-256 du refresh token est stocké. À chaque refresh,
-- le token est renouvelé ; l'ancien hash est gardé pour détecter un vol.
CREATE TABLE sessions (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              BIGINT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  refresh_token_hash   BYTEA        NOT NULL,
  previous_token_hash  BYTEA,
  device_name          VARCHAR(100),
  user_agent           VARCHAR(255),
  ip                   INET,
  remember             BOOLEAN      NOT NULL DEFAULT false,
  created_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),
  last_used_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
  expires_at           TIMESTAMPTZ  NOT NULL,
  revoked_at           TIMESTAMPTZ,
  revoked_reason       VARCHAR(40)
);
CREATE UNIQUE INDEX sessions_refresh_hash_uq ON sessions (refresh_token_hash);
CREATE INDEX sessions_previous_hash_idx      ON sessions (previous_token_hash) WHERE previous_token_hash IS NOT NULL;
CREATE INDEX sessions_user_active_idx        ON sessions (user_id) WHERE revoked_at IS NULL;

-- ── Tentatives de connexion (anti brute-force) ──────────────
CREATE TABLE login_attempts (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  identifier  VARCHAR(254) NOT NULL,
  ip          INET,
  success     BOOLEAN      NOT NULL,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX login_attempts_identifier_idx ON login_attempts (lower(identifier), created_at DESC);
CREATE INDEX login_attempts_ip_idx         ON login_attempts (ip, created_at DESC);

-- ── Réinitialisation du mot de passe ────────────────────────
CREATE TABLE password_resets (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     BIGINT      NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  token_hash  BYTEA       NOT NULL UNIQUE,
  ip          INET,
  expires_at  TIMESTAMPTZ NOT NULL,
  used_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX password_resets_user_idx ON password_resets (user_id);

-- ── Journal de sécurité ─────────────────────────────────────
CREATE TABLE security_logs (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  event       VARCHAR(50) NOT NULL,
  user_id     BIGINT      REFERENCES users (id) ON DELETE SET NULL,
  ip          INET,
  details     JSONB       NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX security_logs_user_idx  ON security_logs (user_id, created_at DESC);
CREATE INDEX security_logs_event_idx ON security_logs (event, created_at DESC);
