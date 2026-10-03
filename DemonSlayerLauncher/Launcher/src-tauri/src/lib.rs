mod api;
mod commands;
mod config;
mod error;
mod session;
mod state;

use tauri::Manager;

use crate::api::ApiClient;
use crate::session::SessionStore;
use crate::state::AppState;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        // Une seule instance : relancer l'exe remet la fenêtre existante au premier plan.
        .plugin(tauri_plugin_single_instance::init(|app, _args, _cwd| {
            if let Some(window) = app.get_webview_window("main") {
                let _ = window.unminimize();
                let _ = window.show();
                let _ = window.set_focus();
            }
        }))
        .plugin(tauri_plugin_opener::init())
        .setup(|app| {
            let config = config::load(app.handle())?;
            let api = ApiClient::new(&config)?;
            log::info!("API : {} (source : {})", config.api_base_url, config.source);
            app.manage(AppState { config, api, session: SessionStore::default() });
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::app::app_info,
            commands::app::api_ping,
            commands::app::launcher_public_config,
            commands::app::open_external,
            commands::auth::auth_login,
            commands::auth::auth_register,
            commands::auth::auth_restore,
            commands::auth::auth_logout,
            commands::auth::auth_logout_all,
            commands::auth::auth_forgot_password,
            commands::auth::auth_reset_password,
            commands::api::api_request,
        ])
        .run(tauri::generate_context!())
        .expect("Impossible de démarrer le launcher Demon Slayer RP");
}
