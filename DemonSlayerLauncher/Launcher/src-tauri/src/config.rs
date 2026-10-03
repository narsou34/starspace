//! Configuration du launcher. Aucune adresse n'est codée en dur dans le code :
//! elle provient du fichier `launcher.config.json` livré avec l'installateur,
//! éventuellement surchargé par l'utilisateur dans %APPDATA%.

use std::{fs, path::PathBuf, time::Duration};

use serde::Deserialize;
use tauri::{AppHandle, Manager};
use url::Url;

const CONFIG_FILE: &str = "launcher.config.json";

#[derive(Debug, Default, Deserialize)]
#[serde(rename_all = "camelCase")]
struct ConfigFile {
    api_base_url: Option<String>,
    request_timeout_seconds: Option<u64>,
}

#[derive(Debug, Clone)]
pub struct LauncherConfig {
    /// URL de base de l'API, sans « / » final.
    pub api_base_url: String,
    pub request_timeout: Duration,
    /// D'où provient la configuration (affiché dans les paramètres / logs).
    pub source: String,
}

fn read_file(path: &PathBuf) -> Option<ConfigFile> {
    let raw = fs::read_to_string(path).ok()?;
    match serde_json::from_str(&raw) {
        Ok(cfg) => Some(cfg),
        Err(err) => {
            log::warn!("Configuration ignorée ({}): {err}", path.display());
            None
        }
    }
}

/// HTTPS obligatoire, sauf pour une API locale de développement.
fn validate_api_url(raw: &str) -> Result<String, String> {
    let url = Url::parse(raw.trim()).map_err(|e| format!("apiBaseUrl invalide « {raw} » : {e}"))?;
    let local = matches!(url.host_str(), Some("localhost" | "127.0.0.1" | "[::1]"));
    match url.scheme() {
        "https" => {}
        "http" if local => {}
        _ => return Err(format!("apiBaseUrl doit utiliser HTTPS : « {raw} »")),
    }
    if url.query().is_some() || url.fragment().is_some() || !url.username().is_empty() {
        return Err(format!("apiBaseUrl ne doit contenir ni paramètres ni identifiants : « {raw} »"));
    }
    Ok(url.as_str().trim_end_matches('/').to_string())
}

pub fn load(app: &AppHandle) -> Result<LauncherConfig, String> {
    let mut candidates: Vec<(String, ConfigFile)> = Vec::new();

    // 1. Variable d'environnement (développement uniquement)
    if cfg!(debug_assertions) {
        if let Ok(url) = std::env::var("DSRP_API_URL") {
            candidates.push((
                "DSRP_API_URL".into(),
                ConfigFile { api_base_url: Some(url), request_timeout_seconds: None },
            ));
        }
    }
    // 2. Surcharge utilisateur : %APPDATA%/com.demonslayerrp.launcher/launcher.config.json
    if let Ok(dir) = app.path().app_config_dir() {
        let path = dir.join(CONFIG_FILE);
        if let Some(cfg) = read_file(&path) {
            candidates.push((path.display().to_string(), cfg));
        }
    }
    // 3. Fichier livré avec l'installateur (release) ; API locale en développement
    if cfg!(debug_assertions) {
        candidates.push((
            "défaut développement".into(),
            ConfigFile { api_base_url: Some("http://127.0.0.1:8080".into()), request_timeout_seconds: None },
        ));
    } else if let Ok(dir) = app.path().resource_dir() {
        let path = dir.join(CONFIG_FILE);
        if let Some(cfg) = read_file(&path) {
            candidates.push((path.display().to_string(), cfg));
        }
    }

    let timeout = candidates
        .iter()
        .find_map(|(_, c)| c.request_timeout_seconds)
        .unwrap_or(15)
        .clamp(3, 120);

    let (source, raw_url) = candidates
        .iter()
        .find_map(|(src, c)| c.api_base_url.as_ref().map(|u| (src.clone(), u.clone())))
        .ok_or_else(|| "Aucune adresse d'API configurée (launcher.config.json manquant).".to_string())?;

    Ok(LauncherConfig {
        api_base_url: validate_api_url(&raw_url)?,
        request_timeout: Duration::from_secs(timeout),
        source,
    })
}

#[cfg(test)]
mod tests {
    use super::validate_api_url;

    #[test]
    fn accepte_https_et_localhost() {
        assert_eq!(validate_api_url("https://api.dsrp.fr/").unwrap(), "https://api.dsrp.fr");
        assert_eq!(validate_api_url("https://dsrp.fr/v1/").unwrap(), "https://dsrp.fr/v1");
        assert!(validate_api_url("http://127.0.0.1:8080").is_ok());
        assert!(validate_api_url("http://localhost:8080").is_ok());
    }

    #[test]
    fn refuse_http_distant_et_urls_douteuses() {
        assert!(validate_api_url("http://api.dsrp.fr").is_err());
        assert!(validate_api_url("ftp://api.dsrp.fr").is_err());
        assert!(validate_api_url("https://user:pw@api.dsrp.fr").is_err());
        assert!(validate_api_url("https://api.dsrp.fr/?x=1").is_err());
        assert!(validate_api_url("pas une url").is_err());
    }
}
