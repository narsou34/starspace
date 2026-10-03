use crate::api::ApiClient;
use crate::config::LauncherConfig;
use crate::session::SessionStore;

pub struct AppState {
    pub config: LauncherConfig,
    pub api: ApiClient,
    pub session: SessionStore,
}
