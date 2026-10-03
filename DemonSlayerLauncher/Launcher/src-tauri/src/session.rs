//! Gestion de la session joueur côté Rust.
//!
//! - L'access token (15 min) reste en mémoire uniquement.
//! - Le refresh token est conservé dans le Gestionnaire d'identification
//!   Windows (Credential Manager) seulement si « Rester connecté » est coché.
//! - Le JavaScript de l'interface ne voit jamais aucun token.

use std::time::{Duration, Instant};

use reqwest::Method;
use serde::Deserialize;
use serde_json::{json, Value};
use tokio::sync::Mutex;

use crate::api::ApiClient;
use crate::error::{LauncherError, LauncherResult};

const KEYRING_SERVICE: &str = "DemonSlayerRP Launcher";
const KEYRING_ACCOUNT: &str = "refresh-token";
/// Marge avant expiration à partir de laquelle on renouvelle l'access token.
const REFRESH_MARGIN: Duration = Duration::from_secs(30);

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthResponse {
    pub user: Value,
    access_token: String,
    /// Absent sur une API plus ancienne : on renouvelle alors prudemment.
    #[serde(default = "default_access_ttl")]
    access_token_expires_in: u64,
    refresh_token: String,
}

fn default_access_ttl() -> u64 {
    60
}

struct Tokens {
    access: String,
    access_expires: Instant,
    refresh: String,
    remember: bool,
}

#[derive(Default)]
pub struct SessionStore {
    inner: Mutex<Option<Tokens>>,
}

// ── Stockage sécurisé du refresh token ─────────────────────────
mod vault {
    use super::{KEYRING_ACCOUNT, KEYRING_SERVICE};

    fn entry() -> Option<keyring::Entry> {
        keyring::Entry::new(KEYRING_SERVICE, KEYRING_ACCOUNT)
            .map_err(|e| log::warn!("Coffre sécurisé indisponible : {e}"))
            .ok()
    }

    pub fn save(token: &str) {
        if let Some(e) = entry() {
            if let Err(err) = e.set_password(token) {
                log::warn!("Impossible d'enregistrer la session : {err}");
            }
        }
    }

    pub fn load() -> Option<String> {
        entry()?.get_password().ok()
    }

    pub fn clear() {
        if let Some(e) = entry() {
            let _ = e.delete_credential();
        }
    }
}

impl SessionStore {
    /// Construit une session après connexion / inscription / refresh et
    /// synchronise le coffre sécurisé selon « Rester connecté ».
    fn tokens_from(auth: &AuthResponse, remember: bool) -> Tokens {
        if remember {
            vault::save(&auth.refresh_token);
        } else {
            vault::clear();
        }
        Tokens {
            access: auth.access_token.clone(),
            access_expires: Instant::now() + Duration::from_secs(auth.access_token_expires_in),
            refresh: auth.refresh_token.clone(),
            remember,
        }
    }

    pub async fn authenticate(
        &self,
        api: &ApiClient,
        path: &str,
        body: Value,
        remember: bool,
    ) -> LauncherResult<Value> {
        let res = api.send(Method::POST, path, Some(&body), None).await?;
        let auth: AuthResponse = serde_json::from_value(res.unwrap_or(Value::Null))
            .map_err(|e| LauncherError::Internal(format!("réponse d'authentification invalide : {e}")))?;
        *self.inner.lock().await = Some(Self::tokens_from(&auth, remember));
        Ok(auth.user)
    }

    /// Restaure la session « Rester connecté » au démarrage.
    /// Idempotent : le verrou est conservé pendant tout l'appel, et une session
    /// déjà active n'est jamais rafraîchie deux fois (sinon la détection de
    /// réutilisation du refresh token la révoquerait).
    pub async fn restore(&self, api: &ApiClient) -> LauncherResult<Option<Value>> {
        let mut guard = self.inner.lock().await;
        if let Some(tokens) = guard.as_ref() {
            if tokens.access_expires > Instant::now() + REFRESH_MARGIN {
                let profile = api.send(Method::GET, "/api/user/profile", None, Some(&tokens.access)).await?;
                return Ok(profile.and_then(|p| p.get("user").cloned()));
            }
        }
        let refresh = match guard.as_ref() {
            Some(tokens) => tokens.refresh.clone(),
            None => match vault::load() {
                Some(token) => token,
                None => return Ok(None),
            },
        };
        let remember = guard.as_ref().map_or(true, |t| t.remember);
        match Self::call_refresh(api, &refresh).await {
            Ok(auth) => {
                *guard = Some(Self::tokens_from(&auth, remember));
                Ok(Some(auth.user))
            }
            Err(err) if err.ends_session() => {
                *guard = None;
                vault::clear();
                Ok(None)
            }
            // Erreur réseau : on garde le token pour réessayer plus tard.
            Err(err) => Err(err),
        }
    }

    async fn call_refresh(api: &ApiClient, refresh: &str) -> LauncherResult<AuthResponse> {
        let res = api
            .send(Method::POST, "/api/auth/refresh", Some(&json!({ "refreshToken": refresh })), None)
            .await?;
        serde_json::from_value(res.unwrap_or(Value::Null))
            .map_err(|e| LauncherError::Internal(format!("réponse de refresh invalide : {e}")))
    }

    /// Renvoie un access token valide, en le renouvelant si besoin.
    /// `stale` : token qui vient d'être refusé (401) → refresh forcé.
    async fn access_token(&self, api: &ApiClient, stale: Option<&str>) -> LauncherResult<String> {
        // Le verrou est conservé pendant le refresh : deux requêtes simultanées
        // ne déclenchent jamais deux rotations concurrentes.
        let mut guard = self.inner.lock().await;
        let tokens = guard.as_mut().ok_or(LauncherError::NotAuthenticated)?;

        let expired = tokens.access_expires <= Instant::now() + REFRESH_MARGIN;
        let rejected = stale.is_some_and(|s| s == tokens.access);
        if !expired && !rejected {
            return Ok(tokens.access.clone());
        }

        match Self::call_refresh(api, &tokens.refresh).await {
            Ok(auth) => {
                tokens.access = auth.access_token;
                tokens.access_expires = Instant::now() + Duration::from_secs(auth.access_token_expires_in);
                tokens.refresh = auth.refresh_token;
                if tokens.remember {
                    vault::save(&tokens.refresh);
                }
                Ok(tokens.access.clone())
            }
            Err(err) if err.ends_session() => {
                *guard = None;
                vault::clear();
                Err(match err {
                    LauncherError::Api { ref code, .. } if code == "ACCOUNT_SUSPENDED" => err,
                    _ => LauncherError::NotAuthenticated,
                })
            }
            Err(err) => Err(err),
        }
    }

    /// Requête authentifiée avec renouvellement transparent du token.
    pub async fn request(
        &self,
        api: &ApiClient,
        method: Method,
        path: &str,
        body: Option<&Value>,
    ) -> LauncherResult<Option<Value>> {
        let token = self.access_token(api, None).await?;
        match api.send(method.clone(), path, body, Some(&token)).await {
            Err(LauncherError::Api { status: 401, .. }) => {
                let fresh = self.access_token(api, Some(&token)).await?;
                api.send(method, path, body, Some(&fresh)).await
            }
            other => other,
        }
    }

    /// Déconnexion : révocation côté serveur (best effort) puis effacement local.
    pub async fn logout(&self, api: &ApiClient) {
        let tokens = self.inner.lock().await.take();
        vault::clear();
        if let Some(t) = tokens {
            let body = json!({ "refreshToken": t.refresh });
            if let Err(err) = api.send(Method::POST, "/api/auth/logout", Some(&body), None).await {
                log::warn!("Révocation distante impossible : {err}");
            }
        }
    }

    /// Efface la session locale sans appel réseau (ex. après « déconnecter partout »).
    pub async fn clear_local(&self) {
        self.inner.lock().await.take();
        vault::clear();
    }
}

#[cfg(test)]
impl SessionStore {
    /// Simule l'expiration de l'access token.
    async fn expire_access_for_test(&self) {
        if let Some(t) = self.inner.lock().await.as_mut() {
            t.access_expires = Instant::now();
        }
    }

    async fn refresh_token_for_test(&self) -> Option<String> {
        self.inner.lock().await.as_ref().map(|t| t.refresh.clone())
    }
}

/// Tests d'intégration contre une API réelle :
///   DSRP_TEST_API=http://127.0.0.1:8080 cargo test -- --ignored --test-threads=1
#[cfg(test)]
mod integration {
    use std::sync::Arc;
    use std::time::{Duration, SystemTime, UNIX_EPOCH};

    use super::*;
    use crate::config::LauncherConfig;

    fn client() -> Option<ApiClient> {
        let base = std::env::var("DSRP_TEST_API").ok()?;
        let config = LauncherConfig {
            api_base_url: base,
            request_timeout: Duration::from_secs(10),
            source: "test".into(),
        };
        Some(ApiClient::new(&config).expect("client"))
    }

    #[tokio::test]
    #[ignore = "nécessite une API locale (DSRP_TEST_API)"]
    async fn cycle_de_session_complet() {
        let Some(api) = client() else { return };
        let suffix = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_millis() % 1_000_000_000;
        let username = format!("rust{suffix}");
        let session = Arc::new(SessionStore::default());

        // Inscription avec « Rester connecté »
        let user = session
            .authenticate(
                &api,
                "/api/auth/register",
                json!({
                    "username": username,
                    "email": format!("{username}@example.com"),
                    "password": "Respiration2026",
                    "rememberMe": true,
                    "deviceName": "test rust",
                }),
                true,
            )
            .await
            .expect("inscription");
        assert_eq!(user["username"], username.as_str());

        let profile = session.request(&api, Method::GET, "/api/user/profile", None).await.unwrap().unwrap();
        assert_eq!(profile["user"]["username"], username.as_str());

        // Access token expiré + 6 requêtes simultanées : un seul refresh doit avoir lieu,
        // sinon la détection de réutilisation révoquerait la session.
        let before = session.refresh_token_for_test().await;
        session.expire_access_for_test().await;
        let mut handles = Vec::new();
        for _ in 0..6 {
            let s = session.clone();
            let a = client().unwrap();
            handles.push(tokio::spawn(async move {
                s.request(&a, Method::GET, "/api/user/profile", None).await
            }));
        }
        for h in handles {
            h.await.unwrap().expect("requête après refresh");
        }
        assert_ne!(before, session.refresh_token_for_test().await, "le refresh token doit avoir tourné");

        // Redémarrage du launcher : restauration depuis le coffre sécurisé (si disponible).
        if vault::load().is_some() {
            let restarted = SessionStore::default();
            let restored = restarted.restore(&api).await.expect("restore").expect("session restaurée");
            assert_eq!(restored["username"], username.as_str());
            // Restaurer deux fois ne doit pas révoquer la session.
            restarted.restore(&api).await.expect("restore 2").expect("toujours connecté");
            restarted.logout(&api).await;
        } else {
            eprintln!("Coffre sécurisé indisponible dans cet environnement : restauration non testée.");
            session.logout(&api).await;
        }

        assert!(vault::load().is_none(), "le coffre doit être vidé à la déconnexion");
        let after = session.request(&api, Method::GET, "/api/user/profile", None).await;
        assert!(after.is_err(), "la session ne doit plus être utilisable");
    }

    #[tokio::test]
    #[ignore = "nécessite une API locale (DSRP_TEST_API)"]
    async fn erreurs_lisibles() {
        let Some(api) = client() else { return };
        let session = SessionStore::default();
        let err = session
            .authenticate(
                &api,
                "/api/auth/login",
                json!({ "login": "personne-inconnue", "password": "x" }),
                false,
            )
            .await
            .unwrap_err();
        assert_eq!(err.code(), "INVALID_CREDENTIALS");
        assert_eq!(err.to_string(), "Identifiant ou mot de passe incorrect.");
        let json = serde_json::to_value(&err).unwrap();
        assert_eq!(json["status"], 401);
    }
}
