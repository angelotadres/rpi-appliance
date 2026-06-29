import { invoke } from "@tauri-apps/api/core";

type ConnectInfo = { url: string; local_port: number };

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;
const val = (id: string) => ($(id) as HTMLInputElement).value.trim();
const num = (id: string) => Number(($(id) as HTMLInputElement).value);

function showViewer(info: ConnectInfo, host: string) {
  $("connect").classList.add("hidden");
  $("viewer").classList.remove("hidden");
  $("viewer-label").textContent = `${host} — :${info.local_port}`;
  ($("gui") as HTMLIFrameElement).src = info.url;
}

function showConnect(status = "") {
  ($("gui") as HTMLIFrameElement).src = "about:blank";
  $("viewer").classList.add("hidden");
  $("connect").classList.remove("hidden");
  setStatus(status);
}

function setStatus(msg: string, kind: "" | "error" | "busy" = "") {
  const el = $("status");
  el.textContent = msg;
  el.className = `status ${kind}`;
}

async function onConnect(e: Event) {
  e.preventDefault();
  const host = val("host");
  const btn = $("connect-btn") as HTMLButtonElement;
  btn.disabled = true;
  setStatus("Opening tunnel…", "busy");
  try {
    const info = await invoke<ConnectInfo>("connect", {
      opts: {
        host,
        user: val("user"),
        key_path: val("key"),
        remote_port: num("remote_port"),
        local_port: num("local_port"),
        ssh_port: num("ssh_port"),
      },
    });
    setStatus("");
    showViewer(info, host);
  } catch (err) {
    setStatus(String(err), "error");
  } finally {
    btn.disabled = false;
  }
}

async function onDisconnect() {
  try {
    await invoke("disconnect");
  } catch (err) {
    console.error(err);
  }
  showConnect("Disconnected.");
}

window.addEventListener("DOMContentLoaded", () => {
  $("connect-form").addEventListener("submit", onConnect);
  $("disconnect-btn").addEventListener("click", onDisconnect);
});
