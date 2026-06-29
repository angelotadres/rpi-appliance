//! First-time setup: generate a key, push it using the one-off setup password, then
//! run the appliance `lockdown`. We keep using the OS `ssh`/`ssh-keygen` (no bundled
//! SSH stack); the password is fed non-interactively via a short-lived SSH_ASKPASS
//! helper, never on argv.
use std::io::Write;
use std::process::{Command, Stdio};

#[derive(serde::Deserialize, Clone, Debug)]
pub struct SetupOpts {
    pub host: String,
    pub user: String,
    pub password: String,
    pub key_path: String,
    #[serde(default = "default_ssh_port")]
    pub ssh_port: u16,
}
fn default_ssh_port() -> u16 {
    22
}

fn home() -> String {
    std::env::var("HOME")
        .or_else(|_| std::env::var("USERPROFILE"))
        .unwrap_or_else(|_| ".".into())
}

/// Expand a leading `~/` to the user's home directory (ssh-keygen won't do it for us).
pub fn expand_tilde(p: &str) -> String {
    if let Some(rest) = p.strip_prefix("~/") {
        format!("{}/{}", home(), rest)
    } else if p == "~" {
        home()
    } else {
        p.to_string()
    }
}

/// `ssh-keygen` args for a quiet, no-passphrase ed25519 key at `path`.
pub fn keygen_args(path: &str) -> Vec<String> {
    vec![
        "-t".into(),
        "ed25519".into(),
        "-N".into(),
        "".into(),
        "-C".into(),
        "rpi-appliance-client".into(),
        "-f".into(),
        path.into(),
    ]
}

/// ssh args for the one-off **password** session (no pubkey, single prompt).
pub fn password_ssh_args(o: &SetupOpts, remote_cmd: Option<&str>) -> Vec<String> {
    let mut a = vec![
        "-T".into(),
        "-p".into(),
        o.ssh_port.to_string(),
        "-o".into(),
        "StrictHostKeyChecking=accept-new".into(),
        "-o".into(),
        "PreferredAuthentications=password".into(),
        "-o".into(),
        "PubkeyAuthentication=no".into(),
        "-o".into(),
        "NumberOfPasswordPrompts=1".into(),
        format!("{}@{}", o.user, o.host),
    ];
    if let Some(cmd) = remote_cmd {
        a.push(cmd.into());
    }
    a
}

/// ssh args for a **key-only** command session (reusable for verify/lockdown/shutdown).
pub fn pubkey_ssh_args(
    host: &str,
    user: &str,
    ssh_port: u16,
    key_path: &str,
    remote_cmd: &str,
) -> Vec<String> {
    vec![
        "-i".into(),
        key_path.into(),
        "-T".into(),
        "-p".into(),
        ssh_port.to_string(),
        "-o".into(),
        "IdentitiesOnly=yes".into(), // offer ONLY this key (not agent/default keys)
        "-o".into(),
        "StrictHostKeyChecking=accept-new".into(),
        "-o".into(),
        "PreferredAuthentications=publickey".into(),
        "-o".into(),
        "PasswordAuthentication=no".into(),
        "-o".into(),
        "BatchMode=yes".into(),
        format!("{}@{}", user, host),
        remote_cmd.into(),
    ]
}

/// Contents of the temporary SSH_ASKPASS helper: print the password from the env.
pub fn askpass_script() -> &'static str {
    "#!/bin/sh\nprintf '%s' \"$RPI_SETUP_PW\"\n"
}

#[cfg(unix)]
fn write_askpass() -> std::io::Result<std::path::PathBuf> {
    use std::os::unix::fs::PermissionsExt;
    let path = std::env::temp_dir().join(format!("rpi-askpass-{}.sh", std::process::id()));
    std::fs::write(&path, askpass_script())?;
    std::fs::set_permissions(&path, std::fs::Permissions::from_mode(0o700))?;
    Ok(path)
}
#[cfg(not(unix))]
fn write_askpass() -> std::io::Result<std::path::PathBuf> {
    let path = std::env::temp_dir().join(format!("rpi-askpass-{}.cmd", std::process::id()));
    std::fs::write(&path, "@echo %RPI_SETUP_PW%\n")?;
    Ok(path)
}

struct Run {
    ok: bool,
    out: String,
}

fn run_password(o: &SetupOpts, remote_cmd: Option<&str>, stdin_data: Option<&str>) -> Result<Run, String> {
    let askpass = write_askpass().map_err(|e| format!("askpass: {e}"))?;
    let mut cmd = Command::new("ssh");
    cmd.args(password_ssh_args(o, remote_cmd))
        .env("SSH_ASKPASS", &askpass)
        .env("SSH_ASKPASS_REQUIRE", "force")
        .env("DISPLAY", ":0")
        .env("RPI_SETUP_PW", &o.password)
        .stdin(if stdin_data.is_some() { Stdio::piped() } else { Stdio::null() })
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    let mut child = cmd.spawn().map_err(|e| format!("could not start ssh: {e}"))?;
    if let Some(data) = stdin_data {
        child.stdin.take().unwrap().write_all(data.as_bytes()).map_err(|e| e.to_string())?;
    }
    let out = child.wait_with_output().map_err(|e| e.to_string())?;
    let _ = std::fs::remove_file(&askpass);
    Ok(Run {
        ok: out.status.success(),
        out: format!(
            "{}{}",
            String::from_utf8_lossy(&out.stdout),
            String::from_utf8_lossy(&out.stderr)
        )
        .trim()
        .to_string(),
    })
}

fn run_pubkey(
    host: &str,
    user: &str,
    ssh_port: u16,
    key_path: &str,
    remote_cmd: &str,
) -> Result<Run, String> {
    let out = Command::new("ssh")
        .args(pubkey_ssh_args(host, user, ssh_port, key_path, remote_cmd))
        .output()
        .map_err(|e| format!("could not start ssh: {e}"))?;
    Ok(Run {
        ok: out.status.success(),
        out: format!(
            "{}{}",
            String::from_utf8_lossy(&out.stdout),
            String::from_utf8_lossy(&out.stderr)
        )
        .trim()
        .to_string(),
    })
}

/// Generate an ed25519 keypair at `key_path` (no-op if it already exists). Returns the
/// public key text.
pub fn generate_key(key_path: &str) -> Result<String, String> {
    let path = expand_tilde(key_path);
    let pubpath = format!("{path}.pub");
    if std::path::Path::new(&path).exists() {
        return std::fs::read_to_string(&pubpath)
            .map_err(|e| format!("key exists but its .pub is unreadable: {e}"));
    }
    if let Some(parent) = std::path::Path::new(&path).parent() {
        std::fs::create_dir_all(parent).map_err(|e| format!("could not create {parent:?}: {e}"))?;
    }
    let out = Command::new("ssh-keygen")
        .args(keygen_args(&path))
        .output()
        .map_err(|e| format!("could not run ssh-keygen: {e}"))?;
    if !out.status.success() {
        return Err(format!("ssh-keygen failed: {}", String::from_utf8_lossy(&out.stderr).trim()));
    }
    std::fs::read_to_string(&pubpath).map_err(|e| format!("could not read public key: {e}"))
}

/// Push the public key with the one-off password, verify a key-only login works, then
/// run `lockdown`. Aborts before lockdown if the key can't authenticate (no lockout).
pub fn provision(o: &SetupOpts) -> Result<String, String> {
    let key_path = expand_tilde(&o.key_path);
    let pubkey = std::fs::read_to_string(format!("{key_path}.pub"))
        .map_err(|e| format!("could not read public key {key_path}.pub: {e}"))?;
    let mut log = String::new();

    // 1. Push the public key over the password session.
    let push_cmd = "umask 077; mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys; \
                    sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys; \
                    chmod 600 ~/.ssh/authorized_keys";
    let r = run_password(o, Some(push_cmd), Some(&pubkey))?;
    if !r.ok {
        return Err(format!("Pushing the key failed (check host/user/setup password). {}", r.out));
    }
    log.push_str("[ OK ] public key installed\n");

    // 2. Verify a key-only login BEFORE disabling passwords.
    let v = run_pubkey(&o.host, &o.user, o.ssh_port, &key_path, "echo verified")?;
    if !v.ok || !v.out.contains("verified") {
        return Err(format!(
            "Key was installed but a key-only login did not work, so lockdown was skipped to avoid locking you out. {}",
            v.out
        ));
    }
    log.push_str("[ OK ] key-only login verified\n");

    // 3. Lock down: disable password auth + invalidate the setup password.
    let l = run_pubkey(
        &o.host,
        &o.user,
        o.ssh_port,
        &key_path,
        "sudo -n /opt/appliance/bin/lockdown",
    )?;
    if !l.ok {
        return Err(format!(
            "Key works, but lockdown failed (is the appliance sudoers drop-in present?). {}",
            l.out
        ));
    }
    log.push_str("[ OK ] appliance locked to key-only\n");
    Ok(log)
}

/// Power the appliance off over the key session (NOPASSWD sudo).
pub fn shutdown(host: &str, user: &str, ssh_port: u16, key_path: &str) -> Result<String, String> {
    let key = expand_tilde(key_path);
    let r = run_pubkey(host, user, ssh_port, &key, "sudo -n poweroff")?;
    // `poweroff` often drops the connection as the host goes down; treat a closed
    // connection as success too.
    if r.ok || r.out.is_empty() || r.out.contains("closed") {
        Ok("Appliance is shutting down.".into())
    } else {
        Err(format!("Shutdown failed: {}", r.out))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn o() -> SetupOpts {
        SetupOpts {
            host: "appliance.local".into(),
            user: "pi".into(),
            password: "s3cret".into(),
            key_path: "~/.ssh/rpi".into(),
            ssh_port: 22,
        }
    }

    #[test]
    fn password_session_is_password_only() {
        let a = password_ssh_args(&o(), Some("whoami"));
        assert!(a.contains(&"PreferredAuthentications=password".to_string()));
        assert!(a.contains(&"PubkeyAuthentication=no".to_string()));
        assert!(a.contains(&"NumberOfPasswordPrompts=1".to_string()));
        assert_eq!(a.last().unwrap(), "whoami");
    }

    #[test]
    fn pubkey_session_is_key_only() {
        let a = pubkey_ssh_args("h", "pi", 22, "/k", "echo verified");
        assert!(a.contains(&"PasswordAuthentication=no".to_string()));
        assert!(a.contains(&"BatchMode=yes".to_string()));
        assert!(a.contains(&"IdentitiesOnly=yes".to_string()));
        let i = a.iter().position(|x| x == "-i").unwrap();
        assert_eq!(a[i + 1], "/k");
        assert_eq!(a.last().unwrap(), "echo verified");
    }

    #[test]
    fn keygen_is_ed25519_no_passphrase() {
        let a = keygen_args("/tmp/k");
        assert!(a.windows(2).any(|w| w[0] == "-t" && w[1] == "ed25519"));
        let n = a.iter().position(|x| x == "-N").unwrap();
        assert_eq!(a[n + 1], ""); // empty passphrase
    }

    #[test]
    fn tilde_expands() {
        std::env::set_var("HOME", "/home/x");
        assert_eq!(expand_tilde("~/.ssh/k"), "/home/x/.ssh/k");
        assert_eq!(expand_tilde("/abs/k"), "/abs/k");
    }

    #[test]
    fn askpass_prints_env_password() {
        assert!(askpass_script().contains("RPI_SETUP_PW"));
    }
}
