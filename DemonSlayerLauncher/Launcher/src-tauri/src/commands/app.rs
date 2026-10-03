use std::time::Instant;

use reqwest::Method;
use serde::Serialize;
use serde_json::Value;
use tauri::{AppHandle, State};
use tauri_plugin_opener::OpenerExt;
use url::Url;

use crate::error::{LauncherError, LauncherResult};
use crate::state::AppState;

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AppInfo {
    version: &'static str,
    api_base_url: String,
    config_source: String,
    os: &'static str,
}

#[tauri::command]
pub fn app_info(state: State<'_, AppState>) -> AppInfo {
    AppInfo {
        version: env!("CARGO_PKG_VERSION"),
        api_base_url: state.api.base_url().to_string(),
        config_source: state.config.source.clone(),
        os: std::env::consts::OS,
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ApiPing {
    online: bool,
    latency_ms: Option<u128>,
}

/// Vérifie que l'API répond et mesure la latence.
#[tauri::command]
pub async fn api_ping(state: State<'_, AppState>) -> LauncherResult<ApiPing> {
    let start = Instant::now();
    let ok = state.api.send(Method::GET, "/api/health", None, None).await.is_ok();
    Ok(ApiPing { online: ok, latency_ms: ok.then(|| start.elapsed().as_millis()) })
}

/// Configuration publique du serveur (nom, liens Discord / site…).
#[tauri::command]
pub async fn launcher_public_config(state: State<'_, AppState>) -> LauncherResult<Value> {
    Ok(state.api.send(Method::GET, "/api/launcher/config", None, None).await?.unwrap_or(Value::Null))
}

/// Ouvre un lien dans le navigateur par défaut. Seuls https:// et mailto: sont acceptés.
#[tauri::command]
pub fn open_external(app: AppHandle, url: String) -> LauncherResult<()> {
    let parsed = Url::parse(&url).map_err(|_| LauncherError::Invalid("Lien invalide.".into()))?;
    if !matches!(parsed.scheme(), "https" | "mailto") {
        return Err(LauncherError::Invalid("Seuls les liens HTTPS sont autorisés.".into()));
    }
    app.opener()
        .open_url(parsed.as_str(), None::<&str>)
        .map_err(|e| LauncherError::Internal(e.to_string()))
}
