//! Tunnel via the OS `ssh`. We shell out (no bundled SSH stack) and manage the child
//! process in Tauri state. `ssh_args` is pure so it can be unit-tested.
use std::io::Read;
use std::net::{Ipv4Addr, SocketAddr, TcpStream};
use std::process::{Child, Command, Stdio};
use std::time::{Duration, Instant};

#[derive(serde::Deserialize, Clone, Debug)]
pub struct ConnectOpts {
    pub host: String,
    pub user: String,
    pub key_path: String,
    #[serde(default = "default_remote_port")]
    pub remote_port: u16,
    #[serde(default = "default_local_port")]
    pub local_port: u16,
    #[serde(default = "default_ssh_port")]
    pub ssh_port: u16,
}

fn default_remote_port() -> u16 {
    5800
}
fn default_local_port() -> u16 {
    5800
}
fn default_ssh_port() -> u16 {
    22
}

/// Build the `ssh` argument vector for a background local port-forward. Key-only
/// (BatchMode), TOFU host key, fail fast if the forward can't bind, keepalives on.
pub fn ssh_args(o: &ConnectOpts) -> Vec<String> {
    vec![
        "-i".into(),
        o.key_path.clone(),
        "-N".into(), // no remote command — just the tunnel
        "-T".into(), // no PTY
        "-L".into(),
        format!("{}:127.0.0.1:{}", o.local_port, o.remote_port),
        "-p".into(),
        o.ssh_port.to_string(),
        "-o".into(),
        "IdentitiesOnly=yes".into(), // use only the provided key
        "-o".into(),
        "ExitOnForwardFailure=yes".into(),
        "-o".into(),
        "StrictHostKeyChecking=accept-new".into(),
        "-o".into(),
        "BatchMode=yes".into(),
        "-o".into(),
        "ServerAliveInterval=15".into(),
        "-o".into(),
        "ServerAliveCountMax=3".into(),
        format!("{}@{}", o.user, o.host),
    ]
}

/// Poll until the local forward port accepts a TCP connection, or the timeout elapses.
pub fn wait_for_port(port: u16, timeout: Duration) -> bool {
    let addr = SocketAddr::from((Ipv4Addr::LOCALHOST, port));
    let deadline = Instant::now() + timeout;
    while Instant::now() < deadline {
        if TcpStream::connect_timeout(&addr, Duration::from_millis(500)).is_ok() {
            return true;
        }
        std::thread::sleep(Duration::from_millis(300));
    }
    false
}

pub fn spawn_ssh(o: &ConnectOpts) -> std::io::Result<Child> {
    Command::new("ssh")
        .args(ssh_args(o))
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::piped())
        .spawn()
}

/// Drain a (killed) child's stderr so we can report why ssh failed.
pub fn drain_stderr(child: &mut Child) -> String {
    let mut out = String::new();
    if let Some(mut err) = child.stderr.take() {
        let _ = err.read_to_string(&mut out);
    }
    out.trim().to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn opts() -> ConnectOpts {
        ConnectOpts {
            host: "pi.local".into(),
            user: "pi".into(),
            key_path: "/home/me/.ssh/id_ed25519".into(),
            remote_port: 5800,
            local_port: 5901,
            ssh_port: 2222,
        }
    }

    #[test]
    fn builds_local_forward() {
        let a = ssh_args(&opts());
        let l = a.iter().position(|x| x == "-L").expect("has -L");
        assert_eq!(a[l + 1], "5901:127.0.0.1:5800");
    }

    #[test]
    fn targets_user_at_host_last() {
        let a = ssh_args(&opts());
        assert_eq!(a.last().unwrap(), "pi@pi.local");
    }

    #[test]
    fn key_only_and_safe_options() {
        let a = ssh_args(&opts());
        assert!(a.contains(&"-N".to_string()));
        assert!(a.contains(&"BatchMode=yes".to_string()));
        assert!(a.contains(&"ExitOnForwardFailure=yes".to_string()));
        assert!(a.contains(&"StrictHostKeyChecking=accept-new".to_string()));
        // key path is passed via -i
        let i = a.iter().position(|x| x == "-i").expect("has -i");
        assert_eq!(a[i + 1], "/home/me/.ssh/id_ed25519");
        // custom ssh port honored
        let p = a.iter().position(|x| x == "-p").expect("has -p");
        assert_eq!(a[p + 1], "2222");
    }

    #[test]
    fn wait_for_port_times_out_on_closed_port() {
        // Port 1 is privileged/unused here; expect a fast timeout, not a hang.
        assert!(!wait_for_port(1, Duration::from_millis(700)));
    }
}
