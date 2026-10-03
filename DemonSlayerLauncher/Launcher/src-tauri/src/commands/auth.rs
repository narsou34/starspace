use reqwest::Method;
use serde_json::{json, Value};
use tauri::State;

use crate::error::LauncherResult;
use crate::state::AppState;

/// Nom d'appareil affiché dans la liste des sessions du compte.
fn device_name() -> String {
    let host = std::env::var("COMPUTERNAME")
        .or_else(|_| std::env::var("HOSTNAME"))
        .unwrap_or_else(|_| "PC".into());
    let name = format!("Launcher · {host}");
    name.chars().take(100).collect()
}

#[tauri::command]
pub async fn auth_login(
    state: State<'_, AppState>,
    login: String,
    password: String,
    remember: bool,
) -> LauncherResult<Value> {
    let body = json!({
        "login": login,
        "password": password,
        "rememberMe": remember,
        "deviceName": device_name(),
    });
    state.session.authenticate(&state.api, "/api/auth/login", body, remember).await
}

#[tauri::command]
pub async fn auth_register(
    state: State<'_, AppState>,
    username: String,
    email: String,
    password: String,
    remember: bool,
) -> LauncherResult<Value> {
    let body = json!({
        "username": username,
        "email": email,
        "password": password,
        "rememberMe": remember,
        "deviceName": device_name(),
    });
    state.session.authenticate(&state.api, "/api/auth/register", body, remember).await
}

/// Restaure la session enregistrée (« Rester connecté »). `null` si aucune.
#[tauri::command]
pub async fn auth_restore(state: State<'_, AppState>) -> LauncherResult<Option<Value>> {
    state.session.restore(&state.api).await
}

#[tauri::command]
pub async fn auth_logout(state: State<'_, AppState>) -> LauncherResult<()> {
    state.session.logout(&state.api).await;
    Ok(())
}

/// Déconnecte tous les appareils du compte, y compris celui-ci.
#[tauri::command]
pub async fn auth_logout_all(state: State<'_, AppState>) -> LauncherResult<()> {
    state.session.request(&state.api, Method::POST, "/api/auth/logout-all", None).await?;
    state.session.clear_local().await;
    Ok(())
}

#[tauri::command]
pub async fn auth_forgot_password(state: State<'_, AppState>, email: String) -> LauncherResult<Value> {
    let body = json!({ "email": email });
    Ok(state.api.send(Method::POST, "/api/auth/forgot-password", Some(&body), None).await?.unwrap_or(Value::Null))
}

#[tauri::command]
pub async fn auth_reset_password(
    state: State<'_, AppState>,
    code: String,
    new_password: String,
) -> LauncherResult<Value> {
    let body = json!({ "code": code, "newPassword": new_password });
    Ok(state.api.send(Method::POST, "/api/auth/reset-password", Some(&body), None).await?.unwrap_or(Value::Null))
}
