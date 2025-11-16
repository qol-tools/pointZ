use anyhow::Result;
use cocoa::appkit::NSApplication;
use core_foundation::runloop::{CFRunLoopGetMain, CFRunLoopWakeUp};
use tray_icon::TrayIconEvent;

use crate::features::command::command_service::CommandService;
use crate::features::discovery::discovery_service::DiscoveryService;
use crate::input;
use crate::tray;
use crate::utils;

const DOWNLOAD_URL: &str = "https://github.com/KMRH47/pointZ-new/releases/latest/download/pointz-app.apk";

/// Run the macOS-specific event loop with NSApplication on the main thread
pub fn run_macos_event_loop() -> Result<()> {
    env_logger::init();
    let tray_manager = tray::TrayManager::new()?;
    let show_qr_tx = tray_manager.get_show_qr_sender();

    wake_core_foundation_run_loop();
    spawn_async_services();
    spawn_tray_event_handler(show_qr_tx);
    run_cocoa_event_loop();

    Ok(())
}

/// Wake up the Core Foundation run loop to ensure tray icon appears
/// See: https://github.com/tauri-apps/tray-icon/issues/90
fn wake_core_foundation_run_loop() {
    unsafe {
        let rl = CFRunLoopGetMain();
        CFRunLoopWakeUp(rl);
    }
}

/// Spawn all async services (discovery and command) in a background thread
fn spawn_async_services() {
    std::thread::spawn(|| {
        let rt = tokio::runtime::Runtime::new()
            .expect("Failed to create Tokio runtime");

        rt.block_on(async {
            run_services().await
                .unwrap_or_else(|e| log::error!("Service initialization error: {}", e));
        });
    });
}

/// Initialize and run discovery and command services
async fn run_services() -> Result<()> {
    let input_handler = input::InputHandler::new()?;
    let discovery_service = DiscoveryService::new().await?;
    let command_service = CommandService::new(input_handler).await?;

    tokio::spawn(async move {
        if let Err(e) = discovery_service.run().await {
            log::error!("Discovery loop error: {}", e);
        }
    });

    command_service.run().await
}

/// Spawn a thread to handle tray icon events
fn spawn_tray_event_handler(show_qr_tx: tokio::sync::mpsc::UnboundedSender<tray::QrData>) {
    std::thread::spawn(move || {
        let receiver = TrayIconEvent::receiver();

        for event in receiver.iter() {
            handle_tray_event(event, &show_qr_tx);
        }
    });
}

/// Handle individual tray icon events
fn handle_tray_event(
    event: TrayIconEvent,
    show_qr_tx: &tokio::sync::mpsc::UnboundedSender<tray::QrData>,
) {
    if matches!(event.click_type, tray_icon::ClickType::Left) {
        let qr_data = create_qr_data();
        let _ = show_qr_tx.send(qr_data);
    }
}

/// Create QR data with current IP and download URL
fn create_qr_data() -> tray::QrData {
    tray::QrData {
        download_url: DOWNLOAD_URL.to_string(),
        ip: get_local_ip_string(),
    }
}

/// Get local IP address as string, fallback to "localhost"
fn get_local_ip_string() -> String {
    utils::get_local_ip()
        .map(|ip| ip.to_string())
        .unwrap_or_else(|| "localhost".to_string())
}

/// Run the Cocoa event loop on the main thread (required for tray icons on macOS)
fn run_cocoa_event_loop() {
    use cocoa::appkit::{NSApp, NSApplicationActivationPolicyAccessory};

    unsafe {
        let app = NSApp();
        app.setActivationPolicy_(NSApplicationActivationPolicyAccessory);
        app.run();
    }
}
