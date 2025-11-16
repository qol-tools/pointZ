mod domain;
mod features;
mod input;
mod utils;
mod tray;

#[cfg(target_os = "macos")]
mod platform;

use anyhow::Result;

#[cfg(not(target_os = "macos"))]
use crate::features::discovery::discovery_service::DiscoveryService;
#[cfg(not(target_os = "macos"))]
use crate::features::command::command_service::CommandService;

#[cfg(not(target_os = "macos"))]
#[tokio::main]
async fn main() -> Result<()> {
    env_logger::init();
    run_standard_event_loop().await
}

#[cfg(target_os = "macos")]
fn main() -> Result<()> {
    platform::run_macos_event_loop()
}

/// Standard event loop for Linux and Windows
#[cfg(not(target_os = "macos"))]
async fn run_standard_event_loop() -> Result<()> {
    let input_handler = input::InputHandler::new()?;
    let discovery_service = DiscoveryService::new().await?;
    let command_service = CommandService::new(input_handler).await?;

    let _tray_manager = tray::TrayManager::new()?;

    spawn_discovery_service(discovery_service);

    command_service.run().await
}

/// Spawn discovery service in background
#[cfg(not(target_os = "macos"))]
fn spawn_discovery_service(discovery_service: DiscoveryService) {
    tokio::spawn(async move {
        if let Err(e) = discovery_service.run().await {
            log::error!("Discovery loop error: {}", e);
        }
    });
}
