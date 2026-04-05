use std::collections::HashMap;
use std::path::Path;
use std::sync::{Arc, atomic::{AtomicU64, Ordering}};
use std::time::{SystemTime, UNIX_EPOCH};

use async_channel::Sender;
use serde::Serialize;
use tokio::fs;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{UnixListener, UnixStream};
use tokio::sync::Mutex;
use zbus::zvariant::ObjectPath;
use zbus::{interface, Connection};

const PANEL_DIR: &str = "/home/Arch/Downloads/vscode/Archthings/.codex-shell/bluetooth-panel";
const SOCKET_PATH: &str = "/home/Arch/Downloads/vscode/Archthings/.codex-shell/bluetooth-panel/runtime/agent.sock";
const READY_PATH: &str = "/home/Arch/Downloads/vscode/Archthings/.codex-shell/bluetooth-panel/runtime/agent-ready";

#[derive(Clone, Serialize, Default)]
struct PairingRequest {
    token: String,
    #[serde(rename = "requestType")]
    request_type: String,
    #[serde(rename = "devicePath")]
    device_path: String,
    #[serde(rename = "deviceName")]
    device_name: String,
    #[serde(rename = "deviceAddress")]
    device_address: String,
    passkey: u32,
    #[serde(rename = "requiresResponse")]
    requires_response: bool,
}

#[derive(Clone, Serialize, Default)]
struct HelperStatus {
    #[serde(rename = "devicePath")]
    device_path: String,
    message: String,
    tone: String,
}

#[derive(Serialize)]
struct StatePayload {
    #[serde(rename = "helperReady")]
    helper_ready: bool,
    request: serde_json::Value,
    status: serde_json::Value,
}

enum PendingResponse {
    Confirm(Sender<bool>),
    Pin(Sender<String>),
    Passkey(Sender<u32>),
}

struct PendingRequest {
    device_path: String,
    responder: PendingResponse,
}

#[derive(Default)]
struct SharedState {
    current_request: Option<PairingRequest>,
    current_status: Option<HelperStatus>,
    pending: HashMap<String, PendingRequest>,
}

struct BluetoothAgent {
    conn: Connection,
    state: Arc<Mutex<SharedState>>,
    token_counter: Arc<AtomicU64>,
}

impl BluetoothAgent {
    fn next_token(&self) -> String {
        let counter = self.token_counter.fetch_add(1, Ordering::Relaxed);
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_millis())
            .unwrap_or(0);
        format!("{now:x}-{counter:x}")
    }

    async fn set_status(&self, device_path: &str, message: &str, tone: &str) {
        let mut state = self.state.lock().await;
        state.current_status = Some(HelperStatus {
            device_path: device_path.to_string(),
            message: message.to_string(),
            tone: tone.to_string(),
        });
    }

    async fn clear_request(&self) {
        let mut state = self.state.lock().await;
        state.current_request = None;
    }

    async fn queue_request(&self, device: &str, request_type: &str, passkey: u32, responder: PendingResponse) -> Result<PairingRequest, zbus::fdo::Error> {
        let (device_name, device_address) = get_device_meta(&self.conn, device).await;
        let token = self.next_token();
        let request = PairingRequest {
            token: token.clone(),
            request_type: request_type.to_string(),
            device_path: device.to_string(),
            device_name,
            device_address,
            passkey,
            requires_response: true,
        };

        let mut state = self.state.lock().await;
        state.pending.insert(token.clone(), PendingRequest {
            device_path: device.to_string(),
            responder,
        });
        state.current_request = Some(request.clone());
        drop(state);
        Ok(request)
    }
}

#[interface(name = "org.bluez.Agent1")]
impl BluetoothAgent {
    async fn release(&self) {}

    async fn request_pin_code(&self, device: ObjectPath<'_>) -> Result<String, zbus::fdo::Error> {
        let (tx, rx) = async_channel::bounded(1);
        let request = self.queue_request(device.as_str(), "pin", 0, PendingResponse::Pin(tx)).await?;
        let response = rx.recv().await.map_err(|_| zbus::fdo::Error::Failed("Request cancelled".into()))?;
        self.clear_request().await;
        if response.is_empty() {
            Err(zbus::fdo::Error::Failed("Empty PIN".into()))
        } else {
            self.set_status(&request.device_path, "已发送 PIN，等待设备响应", "info").await;
            Ok(response)
        }
    }

    async fn display_pin_code(&self, _device: ObjectPath<'_>, _pincode: &str) {}

    async fn request_passkey(&self, device: ObjectPath<'_>) -> Result<u32, zbus::fdo::Error> {
        let (tx, rx) = async_channel::bounded(1);
        let request = self.queue_request(device.as_str(), "passkey", 0, PendingResponse::Passkey(tx)).await?;
        let response = rx.recv().await.map_err(|_| zbus::fdo::Error::Failed("Request cancelled".into()))?;
        self.clear_request().await;
        self.set_status(&request.device_path, "已发送配对码，等待设备响应", "info").await;
        Ok(response)
    }

    async fn display_passkey(&self, _device: ObjectPath<'_>, _passkey: u32, _entered: u16) {}

    async fn request_confirmation(&self, device: ObjectPath<'_>, passkey: u32) -> Result<(), zbus::fdo::Error> {
        let (tx, rx) = async_channel::bounded(1);
        let request = self.queue_request(device.as_str(), "confirm", passkey, PendingResponse::Confirm(tx)).await?;
        let accepted = rx.recv().await.unwrap_or(false);
        self.clear_request().await;
        if accepted {
            self.set_status(&request.device_path, "已确认配对码，等待设备响应", "info").await;
            Ok(())
        } else {
            Err(zbus::fdo::Error::Failed("User rejected confirmation".into()))
        }
    }

    async fn request_authorization(&self, _device: ObjectPath<'_>) -> Result<(), zbus::fdo::Error> {
        Ok(())
    }

    async fn authorize_service(&self, _device: ObjectPath<'_>, _uuid: &str) -> Result<(), zbus::fdo::Error> {
        Ok(())
    }

    async fn cancel(&self) {
        let mut state = self.state.lock().await;
        state.current_request = None;
        state.pending.clear();
    }
}

async fn get_device_meta(conn: &Connection, device_path: &str) -> (String, String) {
    let Ok(path) = ObjectPath::try_from(device_path) else {
        return ("蓝牙设备".into(), "".into());
    };

    let name = conn.call_method(
            Some("org.bluez"),
            &path,
            Some("org.freedesktop.DBus.Properties"),
            "Get",
            &("org.bluez.Device1", "Name"),
        )
        .await
        .ok()
        .and_then(|m| m.body().deserialize::<zbus::zvariant::OwnedValue>().ok())
        .and_then(|v| String::try_from(v).ok())
        .unwrap_or_else(|| "蓝牙设备".into());

    let address = conn.call_method(
            Some("org.bluez"),
            &path,
            Some("org.freedesktop.DBus.Properties"),
            "Get",
            &("org.bluez.Device1", "Address"),
        )
        .await
        .ok()
        .and_then(|m| m.body().deserialize::<zbus::zvariant::OwnedValue>().ok())
        .and_then(|v| String::try_from(v).ok())
        .unwrap_or_default();

    (name, address)
}

async fn set_status(state: &Arc<Mutex<SharedState>>, device_path: &str, message: &str, tone: &str) {
    let mut guard = state.lock().await;
    guard.current_status = Some(HelperStatus {
        device_path: device_path.to_string(),
        message: message.to_string(),
        tone: tone.to_string(),
    });
}

async fn clear_request(state: &Arc<Mutex<SharedState>>) {
    let mut guard = state.lock().await;
    guard.current_request = None;
}

async fn cancel_pairing(conn: &Connection, device_path: &str) {
    let Ok(path) = ObjectPath::try_from(device_path) else {
        return;
    };
    let _ = conn.call_method(
        Some("org.bluez"),
        &path,
        Some("org.bluez.Device1"),
        "CancelPairing",
        &(),
    ).await;
}

async fn pair_device(conn: Connection, state: Arc<Mutex<SharedState>>, device_path: String) {
    set_status(&state, &device_path, "正在发起配对", "info").await;
    clear_request(&state).await;

    let Ok(path) = ObjectPath::try_from(device_path.as_str()) else {
        set_status(&state, &device_path, "配对失败：设备路径无效", "error").await;
        return;
    };

    let result = conn.call_method(
        Some("org.bluez"),
        &path,
        Some("org.bluez.Device1"),
        "Pair",
        &(),
    ).await;

    match result {
        Ok(_) => set_status(&state, &device_path, "配对成功", "success").await,
        Err(err) => set_status(&state, &device_path, &format!("配对失败：{err}"), "error").await,
    }
}

async fn state_json(state: &Arc<Mutex<SharedState>>) -> String {
    let guard = state.lock().await;
    let request = guard.current_request.clone()
        .map(|r| serde_json::to_value(r).unwrap_or_else(|_| serde_json::json!({})))
        .unwrap_or_else(|| serde_json::json!({}));
    let status = guard.current_status.clone()
        .map(|s| serde_json::to_value(s).unwrap_or_else(|_| serde_json::json!({})))
        .unwrap_or_else(|| serde_json::json!({}));

    serde_json::to_string(&StatePayload {
        helper_ready: true,
        request,
        status,
    }).unwrap_or_else(|_| "{\"helperReady\":true,\"request\":{},\"status\":{}}".into())
}

async fn handle_control(conn: Connection, state: Arc<Mutex<SharedState>>, command: String) -> String {
    let mut parts = command.split_whitespace();
    let action = parts.next().unwrap_or("");

    match action {
        "state" => state_json(&state).await,
        "pair" => {
            let device_path = parts.next().unwrap_or("").to_string();
            if !device_path.is_empty() {
                tokio::spawn(pair_device(conn.clone(), state.clone(), device_path));
            }
            "{\"ok\":true}".into()
        }
        "accept" => {
            let token = parts.next().unwrap_or("").to_string();
            let request_type = parts.next().unwrap_or("").to_string();
            let value = parts.collect::<Vec<_>>().join(" ");
            let pending = {
                let mut guard = state.lock().await;
                guard.current_request = None;
                guard.pending.remove(&token)
            };

            if let Some(pending) = pending {
                match pending.responder {
                    PendingResponse::Confirm(tx) => {
                        let _ = tx.send(true).await;
                    }
                    PendingResponse::Pin(tx) => {
                        let _ = tx.send(value).await;
                    }
                    PendingResponse::Passkey(tx) => {
                        let parsed = value.parse::<u32>().unwrap_or(0);
                        let _ = tx.send(parsed).await;
                    }
                }
                let message = if request_type == "confirm" {
                    "已确认配对码，等待设备响应"
                } else {
                    "已提交配对信息，等待设备响应"
                };
                set_status(&state, &pending.device_path, message, "info").await;
            }
            "{\"ok\":true}".into()
        }
        "reject" => {
            let token = parts.next().unwrap_or("").to_string();
            let _request_type = parts.next().unwrap_or("").to_string();
            let device_path = parts.next().unwrap_or("").to_string();
            let pending = {
                let mut guard = state.lock().await;
                guard.current_request = None;
                guard.pending.remove(&token)
            };

            if let Some(pending) = pending {
                match pending.responder {
                    PendingResponse::Confirm(tx) => {
                        let _ = tx.send(false).await;
                    }
                    PendingResponse::Pin(tx) => {
                        let _ = tx.send(String::new()).await;
                    }
                    PendingResponse::Passkey(tx) => {
                        let _ = tx.send(0).await;
                    }
                }
                cancel_pairing(&conn, &pending.device_path).await;
                set_status(&state, &pending.device_path, "已取消本次配对", "muted").await;
            } else if !device_path.is_empty() {
                cancel_pairing(&conn, &device_path).await;
                set_status(&state, &device_path, "已取消本次配对", "muted").await;
            }
            "{\"ok\":true}".into()
        }
        _ => "{\"ok\":false}".into(),
    }
}

async fn serve_socket(conn: Connection, state: Arc<Mutex<SharedState>>) -> Result<(), Box<dyn std::error::Error>> {
    if Path::new(SOCKET_PATH).exists() {
        let _ = fs::remove_file(SOCKET_PATH).await;
    }
    let listener = UnixListener::bind(SOCKET_PATH)?;

    loop {
        let (mut stream, _) = listener.accept().await?;
        let conn = conn.clone();
        let state = state.clone();
        tokio::spawn(async move {
            let mut buf = Vec::new();
            let _ = stream.read_to_end(&mut buf).await;
            let command = String::from_utf8_lossy(&buf).trim().to_string();
            let response = handle_control(conn, state, command).await;
            let _ = stream.write_all(response.as_bytes()).await;
            let _ = stream.shutdown().await;
        });
    }
}

async fn ctl_command(args: &[String]) -> Result<(), Box<dyn std::error::Error>> {
    let mut stream = UnixStream::connect(SOCKET_PATH).await?;
    let command = args.join(" ");
    stream.write_all(command.as_bytes()).await?;
    AsyncWriteExt::shutdown(&mut stream).await?;
    let mut buf = Vec::new();
    stream.read_to_end(&mut buf).await?;
    print!("{}", String::from_utf8_lossy(&buf));
    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().collect();
    if args.get(1).map(|s| s.as_str()) == Some("ctl") {
        return ctl_command(&args[2..]).await;
    }

    fs::create_dir_all(format!("{PANEL_DIR}/runtime")).await?;
    fs::write(READY_PATH, "ready").await?;

    let conn = Connection::system().await?;
    let state = Arc::new(Mutex::new(SharedState::default()));
    let token_counter = Arc::new(AtomicU64::new(1));
    let agent = BluetoothAgent {
        conn: conn.clone(),
        state: state.clone(),
        token_counter: token_counter.clone(),
    };

    conn.object_server().at("/com/archthings/agent", agent).await?;

    let manager_path = ObjectPath::try_from("/org/bluez")?;
    let agent_path = ObjectPath::try_from("/com/archthings/agent")?;

    let _ = conn.call_method(
        Some("org.bluez"),
        &manager_path,
        Some("org.bluez.AgentManager1"),
        "RegisterAgent",
        &(&agent_path, "KeyboardDisplay"),
    ).await?;

    let _ = conn.call_method(
        Some("org.bluez"),
        &manager_path,
        Some("org.bluez.AgentManager1"),
        "RequestDefaultAgent",
        &(&agent_path),
    ).await?;

    serve_socket(conn, state).await?;
    Ok(())
}
