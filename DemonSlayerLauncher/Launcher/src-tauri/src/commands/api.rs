use reqwest::Method;
use serde_json::Value;
use tauri::State;

use crate::error::{LauncherError, LauncherResult};
use crate::state::AppState;

/// Les routes d'authentification passent par des commandes dédiées :
/// l'interface ne peut pas manipuler les tokens via la passerelle générique.
const BLOCKED_PREFIXES: &[&str] = &["/api/auth/"];

fn validate_path(path: &str) -> LauncherResult<()> {
    let ok = path.starts_with("/api/")
        && path.len() <= 512
        && !path.contains("..")
        && !path.contains("//")
        && !path.contains('\\')
        && !path.contains('#')
        && path.chars().all(|c| c.is_ascii_graphic())
        && !BLOCKED_PREFIXES.iter().any(|p| path.starts_with(p));
    if ok {
        Ok(())
    } else {
        Err(LauncherError::Invalid(format!("Chemin d'API refusé : {path}")))
    }
}

fn parse_method(method: &str) -> LauncherResult<Method> {
    match method.to_ascii_uppercase().as_str() {
        "GET" => Ok(Method::GET),
        "POST" => Ok(Method::POST),
        "PUT" => Ok(Method::PUT),
        "PATCH" => Ok(Method::PATCH),
        "DELETE" => Ok(Method::DELETE),
        _ => Err(LauncherError::Invalid(format!("Méthode HTTP refusée : {method}"))),
    }
}

/// Passerelle authentifiée vers l'API (profil, sessions, et phases suivantes).
#[tauri::command]
pub async fn api_request(
    state: State<'_, AppState>,
    method: String,
    path: String,
    body: Option<Value>,
) -> LauncherResult<Option<Value>> {
    validate_path(&path)?;
    let method = parse_method(&method)?;
    state.session.request(&state.api, method, &path, body.as_ref()).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn chemins_valides() {
        assert!(validate_path("/api/user/profile").is_ok());
        assert!(validate_path("/api/user/sessions/9b1d1f0e-0000-4000-8000-000000000000").is_ok());
    }

    #[test]
    fn chemins_refuses() {
        for p in [
            "/api/auth/refresh",
            "/api/../admin",
            "https://evil.example/api/x",
            "//evil.example/api",
            "/api/user profile",
            "/health",
            "/api/user/x#frag",
        ] {
            assert!(validate_path(p).is_err(), "{p} aurait dû être refusé");
        }
    }

    #[test]
    fn methodes() {
        assert!(parse_method("get").is_ok());
        assert!(parse_method("TRACE").is_err());
    }
}
