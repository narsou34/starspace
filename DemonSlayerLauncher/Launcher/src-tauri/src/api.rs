//! Client HTTP vers l'API backend. Tout le trafic réseau passe par Rust :
//! l'interface (WebView) n'a aucun accès direct au réseau ni aux tokens.

use reqwest::{Client, Method, StatusCode};
use serde_json::Value;

use crate::config::LauncherConfig;
use crate::error::{LauncherError, LauncherResult};

pub struct ApiClient {
    http: Client,
    base: String,
}

impl ApiClient {
    pub fn new(config: &LauncherConfig) -> Result<Self, String> {
        let user_agent = format!(
            "DemonSlayerRP-Launcher/{} ({})",
            env!("CARGO_PKG_VERSION"),
            std::env::consts::OS
        );
        let http = Client::builder()
            .user_agent(user_agent)
            .timeout(config.request_timeout)
            .connect_timeout(std::time::Duration::from_secs(8))
            .https_only(config.api_base_url.starts_with("https://"))
            .build()
            .map_err(|e| format!("Client HTTP : {e}"))?;
        Ok(Self { http, base: config.api_base_url.clone() })
    }

    pub fn base_url(&self) -> &str {
        &self.base
    }

    /// Envoie une requête JSON. Renvoie `None` pour une réponse 204.
    pub async fn send(
        &self,
        method: Method,
        path: &str,
        body: Option<&Value>,
        bearer: Option<&str>,
    ) -> LauncherResult<Option<Value>> {
        let mut req = self.http.request(method, format!("{}{}", self.base, path));
        if let Some(token) = bearer {
            req = req.bearer_auth(token);
        }
        if let Some(body) = body {
            req = req.json(body);
        }

        let res = req.send().await.map_err(|e| LauncherError::Network(e.to_string()))?;
        let status = res.status();
        if status == StatusCode::NO_CONTENT {
            return Ok(None);
        }
        let text = res.text().await.map_err(|e| LauncherError::Network(e.to_string()))?;
        let json: Option<Value> = serde_json::from_str(&text).ok();

        if status.is_success() {
            return Ok(Some(json.unwrap_or(Value::Null)));
        }

        let err = json.as_ref().and_then(|j| j.get("error"));
        let field = |name: &str| err.and_then(|e| e.get(name)).and_then(Value::as_str).map(str::to_owned);
        Err(LauncherError::Api {
            status: status.as_u16(),
            code: field("code").unwrap_or_else(|| "HTTP_ERROR".into()),
            message: field("message").unwrap_or_else(|| match status.as_u16() {
                502..=504 => "Le serveur est temporairement indisponible.".into(),
                _ => format!("Erreur inattendue du serveur ({status})."),
            }),
            details: err.and_then(|e| e.get("details")).cloned(),
        })
    }
}
