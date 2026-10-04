use serde::ser::SerializeStruct;
use serde::{Serialize, Serializer};
use serde_json::Value;

/// Erreur transmise à l'interface : toujours { code, message, status?, details? }.
#[derive(Debug, thiserror::Error)]
pub enum LauncherError {
    #[error("{message}")]
    Api {
        status: u16,
        code: String,
        message: String,
        details: Option<Value>,
    },
    #[error("Impossible de joindre le serveur NDR | Demon Slayer. Vérifiez votre connexion internet.")]
    Network(String),
    #[error("Votre session a expiré. Veuillez vous reconnecter.")]
    NotAuthenticated,
    #[error("{0}")]
    Invalid(String),
    #[error("Erreur interne du launcher : {0}")]
    Internal(String),
}

impl LauncherError {
    pub fn code(&self) -> &str {
        match self {
            LauncherError::Api { code, .. } => code,
            LauncherError::Network(_) => "NETWORK_ERROR",
            LauncherError::NotAuthenticated => "SESSION_EXPIRED",
            LauncherError::Invalid(_) => "INVALID_REQUEST",
            LauncherError::Internal(_) => "INTERNAL_ERROR",
        }
    }

    /// La session côté serveur n'est plus valable (expirée, révoquée, compte suspendu).
    pub fn ends_session(&self) -> bool {
        matches!(self, LauncherError::NotAuthenticated)
            || matches!(self, LauncherError::Api { status: 401, .. })
            || matches!(self, LauncherError::Api { code, .. } if code == "ACCOUNT_SUSPENDED")
    }
}

impl Serialize for LauncherError {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let mut s = serializer.serialize_struct("LauncherError", 4)?;
        s.serialize_field("code", self.code())?;
        s.serialize_field("message", &self.to_string())?;
        match self {
            LauncherError::Api { status, details, .. } => {
                s.serialize_field("status", status)?;
                s.serialize_field("details", details)?;
            }
            _ => {
                s.serialize_field("status", &Option::<u16>::None)?;
                s.serialize_field("details", &Option::<Value>::None)?;
            }
        }
        s.end()
    }
}

pub type LauncherResult<T> = Result<T, LauncherError>;
