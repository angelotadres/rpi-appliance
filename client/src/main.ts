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

// ---- First-time setup ----

function setSetupStatus(msg: string, kind: "" | "error" | "busy" | "ok" = "") {
  const el = $("setup-status");
  el.textContent = msg;
  el.className = `status ${kind}`;
}

function showPanel(which: "connect" | "setup") {
  $("connect").classList.toggle("hidden", which !== "connect");
  $("setup").classList.toggle("hidden", which !== "setup");
}

async function onGenerateKey() {
  setSetupStatus("Generating key…", "busy");
  try {
    const pub = await invoke<string>("generate_key", { keyPath: val("s-key") });
    setSetupStatus(`Key ready: ${pub.split(" ").slice(0, 2).join(" ").slice(0, 40)}…`, "ok");
  } catch (err) {
    setSetupStatus(String(err), "error");
  }
}

async function onSetup(e: Event) {
  e.preventDefault();
  const btn = $("setup-btn") as HTMLButtonElement;
  btn.disabled = true;
  setSetupStatus("Pushing key and locking down…", "busy");
  try {
    // Ensure the key exists first (no-op if it already does).
    await invoke<string>("generate_key", { keyPath: val("s-key") });
    const log = await invoke<string>("provision", {
      opts: {
        host: val("s-host"),
        user: val("s-user"),
        password: (($("s-pass") as HTMLInputElement).value),
        key_path: val("s-key"),
        ssh_port: num("s-ssh_port"),
      },
    });
    setSetupStatus(`Done — appliance is key-only.\n${log}`, "ok");
    // Prefill the connect form for immediate use.
    (($("host") as HTMLInputElement).value = val("s-host"));
    (($("user") as HTMLInputElement).value = val("s-user"));
    (($("key") as HTMLInputElement).value = val("s-key"));
  } catch (err) {
    setSetupStatus(String(err), "error");
  } finally {
    btn.disabled = false;
  }
}

window.addEventListener("DOMContentLoaded", () => {
  $("connect-form").addEventListener("submit", onConnect);
  $("disconnect-btn").addEventListener("click", onDisconnect);
  $("to-setup").addEventListener("click", (e) => { e.preventDefault(); showPanel("setup"); });
  $("to-connect").addEventListener("click", (e) => { e.preventDefault(); showPanel("connect"); });
  $("genkey-btn").addEventListener("click", onGenerateKey);
  $("setup-form").addEventListener("submit", onSetup);
});
