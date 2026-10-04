import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { VALID_PASSWORD, createTestContext, destroyTestContext, registerUser, type TestContext } from './helpers.js';

let ctx: TestContext;

beforeEach(async () => {
  ctx = await createTestContext();
});
afterEach(async () => {
  await destroyTestContext(ctx);
});

const login = (login: string, password: string, rememberMe = false) =>
  ctx.app.inject({ method: 'POST', url: '/api/auth/login', payload: { login, password, rememberMe } });

describe('inscription', () => {
  it('crée un compte, renvoie des tokens et ne stocke jamais le mot de passe en clair', async () => {
    const res = await registerUser(ctx.app);
    expect(res.statusCode).toBe(201);
    const body = res.json();
    expect(body.user).toMatchObject({ id: 10000, username: 'Narsou', role: 'player', status: 'active' });
    expect(body.user.password_hash).toBeUndefined();
    expect(body.accessToken).toBeTypeOf('string');
    expect(body.refreshToken).toBeTypeOf('string');
    expect(body.accessTokenExpiresIn).toBe(900);

    const { rows } = await ctx.db.query('SELECT password_hash FROM users');
    expect(rows[0].password_hash).toMatch(/^\$argon2id\$/);
    expect(rows[0].password_hash).not.toContain(VALID_PASSWORD);

    const sessions = await ctx.db.query('SELECT refresh_token_hash FROM sessions');
    expect(sessions.rows[0].refresh_token_hash.toString('base64url')).not.toBe(body.refreshToken);
  });

  it('refuse les doublons de pseudo (insensible à la casse) et d’e-mail', async () => {
    await registerUser(ctx.app);
    const dupName = await registerUser(ctx.app, { username: 'NARSOU', email: 'other@example.com' });
    expect(dupName.statusCode).toBe(409);
    expect(dupName.json().error.code).toBe('USERNAME_TAKEN');

    const dupMail = await registerUser(ctx.app, { username: 'Other', email: 'Narsou@Example.com' });
    expect(dupMail.statusCode).toBe(409);
    expect(dupMail.json().error.code).toBe('EMAIL_TAKEN');
  });

  it('valide les champs (mot de passe faible, pseudo invalide)', async () => {
    const res = await registerUser(ctx.app, { username: 'a b', password: 'court' });
    expect(res.statusCode).toBe(400);
    const { error } = res.json();
    expect(error.code).toBe('VALIDATION_ERROR');
    expect(Object.keys(error.details.fields)).toEqual(expect.arrayContaining(['username', 'password']));
  });

  it('respecte REGISTRATION_ENABLED=false', async () => {
    await destroyTestContext(ctx);
    ctx = await createTestContext({ REGISTRATION_ENABLED: 'false' });
    const res = await registerUser(ctx.app);
    expect(res.statusCode).toBe(403);
    expect(res.json().error.code).toBe('REGISTRATION_DISABLED');
  });
});

describe('connexion', () => {
  beforeEach(async () => {
    await registerUser(ctx.app);
  });

  it('accepte le pseudo ou l’e-mail', async () => {
    expect((await login('narsou', VALID_PASSWORD)).statusCode).toBe(200);
    expect((await login('NARSOU@example.com', VALID_PASSWORD)).statusCode).toBe(200);
  });

  it('renvoie la même erreur pour un compte inconnu et un mauvais mot de passe', async () => {
    const wrong = await login('Narsou', 'mauvais-mdp-123');
    const unknown = await login('inconnu', 'mauvais-mdp-123');
    expect(wrong.statusCode).toBe(401);
    expect(unknown.statusCode).toBe(401);
    expect(wrong.json()).toEqual(unknown.json());
  });

  it('verrouille temporairement après trop d’échecs, même avec le bon mot de passe', async () => {
    for (let i = 0; i < ctx.env.LOGIN_MAX_FAILURES; i++) {
      expect((await login('Narsou', `faux-${i}-abcdef`)).statusCode).toBe(401);
    }
    const locked = await login('Narsou', VALID_PASSWORD);
    expect(locked.statusCode).toBe(429);
    expect(locked.json().error.code).toBe('ACCOUNT_LOCKED');
    expect(Number(locked.headers['retry-after'])).toBeGreaterThan(0);

    const { rows } = await ctx.db.query("SELECT count(*)::int AS n FROM security_logs WHERE event = 'LOGIN_BLOCKED'");
    expect(rows[0].n).toBe(1);
  });

  it('refuse un compte suspendu', async () => {
    await ctx.db.query("UPDATE users SET status = 'suspended'");
    const res = await login('Narsou', VALID_PASSWORD);
    expect(res.statusCode).toBe(403);
    expect(res.json().error.code).toBe('ACCOUNT_SUSPENDED');
  });

  it('journalise USER_LOGIN', async () => {
    await login('Narsou', VALID_PASSWORD);
    const { rows } = await ctx.db.query("SELECT user_id FROM security_logs WHERE event = 'USER_LOGIN'");
    expect(rows).toEqual([{ user_id: 10000 }]);
  });
});

describe('sessions et tokens', () => {
  it('donne accès au profil avec un access token valide', async () => {
    const { accessToken } = (await registerUser(ctx.app)).json();
    const res = await ctx.app.inject({
      method: 'GET',
      url: '/api/user/profile',
      headers: { authorization: `Bearer ${accessToken}` },
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().user.username).toBe('Narsou');
    expect(res.json().permissions).toEqual([]);
  });

  it('refuse les requêtes sans token ou avec un token falsifié', async () => {
    const { accessToken } = (await registerUser(ctx.app)).json();
    const none = await ctx.app.inject({ method: 'GET', url: '/api/user/profile' });
    expect(none.statusCode).toBe(401);

    const tampered = accessToken.slice(0, -4) + 'AAAA';
    const bad = await ctx.app.inject({
      method: 'GET',
      url: '/api/user/profile',
      headers: { authorization: `Bearer ${tampered}` },
    });
    expect(bad.statusCode).toBe(401);
  });

  it('effectue la rotation du refresh token et détecte sa réutilisation', async () => {
    const first = (await registerUser(ctx.app)).json();
    const refresh = (token: string) =>
      ctx.app.inject({ method: 'POST', url: '/api/auth/refresh', payload: { refreshToken: token } });

    const second = await refresh(first.refreshToken);
    expect(second.statusCode).toBe(200);
    const rotated = second.json();
    expect(rotated.refreshToken).not.toBe(first.refreshToken);

    // Réutilisation de l'ancien token → session révoquée (vol présumé).
    const reuse = await refresh(first.refreshToken);
    expect(reuse.statusCode).toBe(401);
    expect(reuse.json().error.code).toBe('SESSION_EXPIRED');

    // Le token légitime le plus récent ne fonctionne plus non plus.
    expect((await refresh(rotated.refreshToken)).statusCode).toBe(401);
    const profile = await ctx.app.inject({
      method: 'GET',
      url: '/api/user/profile',
      headers: { authorization: `Bearer ${rotated.accessToken}` },
    });
    expect(profile.statusCode).toBe(401);

    const { rows } = await ctx.db.query("SELECT revoked_reason FROM sessions");
    expect(rows[0].revoked_reason).toBe('token_reuse');
  });

  it('refuse un refresh token expiré', async () => {
    const { refreshToken } = (await registerUser(ctx.app)).json();
    await ctx.db.query("UPDATE sessions SET expires_at = now() - interval '1 minute'");
    const res = await ctx.app.inject({ method: 'POST', url: '/api/auth/refresh', payload: { refreshToken } });
    expect(res.statusCode).toBe(401);
  });

  it('la déconnexion révoque immédiatement la session', async () => {
    const { accessToken, refreshToken } = (await registerUser(ctx.app)).json();
    const out = await ctx.app.inject({ method: 'POST', url: '/api/auth/logout', payload: { refreshToken } });
    expect(out.statusCode).toBe(204);
    const res = await ctx.app.inject({
      method: 'GET',
      url: '/api/user/profile',
      headers: { authorization: `Bearer ${accessToken}` },
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('SESSION_EXPIRED');
  });

  it('liste les sessions et permet d’en révoquer une autre', async () => {
    const a = (await registerUser(ctx.app)).json();
    const b = (await login('Narsou', VALID_PASSWORD, true)).json();
    const list = await ctx.app.inject({
      method: 'GET',
      url: '/api/user/sessions',
      headers: { authorization: `Bearer ${a.accessToken}` },
    });
    const sessions = list.json().sessions;
    expect(sessions).toHaveLength(2);
    const other = sessions.find((s: { current: boolean }) => !s.current);

    const del = await ctx.app.inject({
      method: 'DELETE',
      url: `/api/user/sessions/${other.id}`,
      headers: { authorization: `Bearer ${a.accessToken}` },
    });
    expect(del.statusCode).toBe(204);
    const bProfile = await ctx.app.inject({
      method: 'GET',
      url: '/api/user/profile',
      headers: { authorization: `Bearer ${b.accessToken}` },
    });
    expect(bProfile.statusCode).toBe(401);
  });

  it('un compte suspendu perd l’accès immédiatement', async () => {
    const { accessToken } = (await registerUser(ctx.app)).json();
    await ctx.db.query("UPDATE users SET status = 'banned'");
    const res = await ctx.app.inject({
      method: 'GET',
      url: '/api/user/profile',
      headers: { authorization: `Bearer ${accessToken}` },
    });
    expect(res.statusCode).toBe(403);
  });
});

describe('mot de passe', () => {
  it('mot de passe oublié : réponse identique, code à usage unique, sessions révoquées', async () => {
    const reg = (await registerUser(ctx.app)).json();
    const forgot = (email: string) =>
      ctx.app.inject({ method: 'POST', url: '/api/auth/forgot-password', payload: { email } });

    const known = await forgot('narsou@example.com');
    const unknown = await forgot('personne@example.com');
    expect(known.statusCode).toBe(200);
    expect(known.json()).toEqual(unknown.json());

    const code = ctx.mailer.lastCodeFor('narsou@example.com');
    expect(code).toMatch(/^[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}$/);

    const reset = (c: string) =>
      ctx.app.inject({
        method: 'POST',
        url: '/api/auth/reset-password',
        payload: { code: c, newPassword: 'NouveauSouffle42' },
      });
    // Le code est accepté sans tirets et en minuscules.
    expect((await reset(code!.replaceAll('-', '').toLowerCase())).statusCode).toBe(200);
    expect((await reset(code!)).json().error.code).toBe('INVALID_RESET_CODE');

    expect((await login('Narsou', VALID_PASSWORD)).statusCode).toBe(401);
    expect((await login('Narsou', 'NouveauSouffle42')).statusCode).toBe(200);

    const refresh = await ctx.app.inject({
      method: 'POST',
      url: '/api/auth/refresh',
      payload: { refreshToken: reg.refreshToken },
    });
    expect(refresh.statusCode).toBe(401);
  });

  it('changement de mot de passe : vérifie l’actuel et déconnecte les autres appareils', async () => {
    const a = (await registerUser(ctx.app)).json();
    const b = (await login('Narsou', VALID_PASSWORD)).json();
    const change = (currentPassword: string) =>
      ctx.app.inject({
        method: 'POST',
        url: '/api/user/password',
        headers: { authorization: `Bearer ${a.accessToken}` },
        payload: { currentPassword, newPassword: 'NouveauSouffle42' },
      });

    expect((await change('mauvais-mdp-1')).statusCode).toBe(400);
    expect((await change(VALID_PASSWORD)).statusCode).toBe(200);

    const mine = await ctx.app.inject({
      method: 'GET',
      url: '/api/user/profile',
      headers: { authorization: `Bearer ${a.accessToken}` },
    });
    expect(mine.statusCode).toBe(200);
    const other = await ctx.app.inject({
      method: 'GET',
      url: '/api/user/profile',
      headers: { authorization: `Bearer ${b.accessToken}` },
    });
    expect(other.statusCode).toBe(401);
  });
});

describe('divers', () => {
  it('expose la configuration publique du launcher', async () => {
    const res = await ctx.app.inject({ method: 'GET', url: '/api/launcher/config' });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toMatchObject({ apiVersion: 1, serverName: 'NDR | Demon Slayer' });
  });

  it('renvoie une erreur JSON propre pour un corps invalide et une route inconnue', async () => {
    const bad = await ctx.app.inject({
      method: 'POST',
      url: '/api/auth/login',
      headers: { 'content-type': 'application/json' },
      payload: '{pas du json',
    });
    expect(bad.statusCode).toBe(400);
    expect(bad.json().error.code).toBe('VALIDATION_ERROR');
    const missing = await ctx.app.inject({ method: 'GET', url: '/api/nope' });
    expect(missing.statusCode).toBe(404);
  });

  it('applique le rate limiting sur les routes d’authentification', async () => {
    await destroyTestContext(ctx);
    ctx = await createTestContext({ AUTH_RATE_LIMIT_PER_MINUTE: '3' });
    const codes: number[] = [];
    for (let i = 0; i < 4; i++) codes.push((await login('x', 'y')).statusCode);
    expect(codes.slice(0, 3)).toEqual([401, 401, 401]);
    expect(codes[3]).toBe(429);
  });
});
