mod ssh;

use std::process::Child;
use std::sync::Mutex;
use std::time::Duration;
use tauri::Manager;

use ssh::{drain_stderr, spawn_ssh, wait_for_port, ConnectOpts};

/// The managed ssh tunnel child (at most one at a time).
#[derive(Default)]
struct Tunnel(Mutex<Option<Child>>);

#[derive(serde::Serialize)]
struct ConnectInfo {
    url: String,
    local_port: u16,
}

fn kill_tunnel(state: &tauri::State<Tunnel>) {
    if let Some(mut child) = state.0.lock().unwrap().take() {
        let _ = child.kill();
        let _ = child.wait();
    }
}

#[tauri::command]
fn connect(opts: ConnectOpts, state: tauri::State<Tunnel>) -> Result<ConnectInfo, String> {
    kill_tunnel(&state); // only one tunnel at a time

    let mut child = spawn_ssh(&opts)
        .map_err(|e| format!("could not start ssh ({e}). Is OpenSSH installed and on PATH?"))?;

    if !wait_for_port(opts.local_port, Duration::from_secs(20)) {
        let _ = child.kill();
        let err = drain_stderr(&mut child);
        let _ = child.wait();
        let detail = if err.is_empty() {
            "the tunnel did not come up within 20s".to_string()
        } else {
            format!("ssh: {err}")
        };
        return Err(format!("Could not open the tunnel — {detail}"));
    }

    *state.0.lock().unwrap() = Some(child);
    Ok(ConnectInfo {
        url: format!("http://localhost:{}", opts.local_port),
        local_port: opts.local_port,
    })
}

#[tauri::command]
fn disconnect(state: tauri::State<Tunnel>) -> Result<(), String> {
    kill_tunnel(&state);
    Ok(())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .manage(Tunnel::default())
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![connect, disconnect])
        .on_window_event(|window, event| {
            // Never leave an orphaned ssh tunnel when the window closes.
            if let tauri::WindowEvent::Destroyed = event {
                if let Some(state) = window.try_state::<Tunnel>() {
                    kill_tunnel(&state);
                }
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
