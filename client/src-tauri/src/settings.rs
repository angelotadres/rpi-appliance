//! Persisted connection settings. We store only non-secret fields — including the
//! key *path*, never the private key itself (it stays where the user put it).
use serde::{Deserialize, Serialize};
use std::path::Path;

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
#[serde(default)]
pub struct Settings {
    pub host: String,
    pub user: String,
    pub key_path: String,
    pub remote_port: u16,
    pub local_port: u16,
    pub ssh_port: u16,
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            host: String::new(),
            user: "pi".into(),
            key_path: String::new(),
            remote_port: 5800,
            local_port: 5800,
            ssh_port: 22,
        }
    }
}

/// Read settings; a missing or corrupt file yields defaults (never an error).
pub fn read_settings(path: &Path) -> Settings {
    std::fs::read_to_string(path)
        .ok()
        .and_then(|s| serde_json::from_str(&s).ok())
        .unwrap_or_default()
}

pub fn write_settings(path: &Path, s: &Settings) -> std::io::Result<()> {
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)?;
    }
    let json = serde_json::to_string_pretty(s).expect("Settings serializes");
    std::fs::write(path, json)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn defaults_are_sane() {
        let d = Settings::default();
        assert_eq!(d.user, "pi");
        assert_eq!((d.remote_port, d.local_port, d.ssh_port), (5800, 5800, 22));
        assert!(d.key_path.is_empty());
    }

    #[test]
    fn round_trips_through_disk() {
        let dir = std::env::temp_dir().join(format!("rpi-settings-{}", std::process::id()));
        let path = dir.join("settings.json");
        let s = Settings {
            host: "appliance.local".into(),
            user: "pi".into(),
            key_path: "~/.ssh/rpi".into(),
            remote_port: 5800,
            local_port: 5901,
            ssh_port: 2222,
        };
        write_settings(&path, &s).unwrap();
        assert_eq!(read_settings(&path), s);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn missing_file_yields_defaults() {
        let path = std::env::temp_dir().join("definitely-not-here-rpi.json");
        assert_eq!(read_settings(&path), Settings::default());
    }
}
