mod domain;
mod features;
mod input;
mod utils;
mod status_server;

use anyhow::Result;

use crate::features::discovery::discovery_service::DiscoveryService;
use crate::features::command::command_service::CommandService;

#[tokio::main]
async fn main() -> Result<()> {
    env_logger::init();

    log::info!("Starting PointZerver (headless mode)...");

    let input_handler = input::InputHandler::new()?;
    let discovery_service = DiscoveryService::new().await?;
    let command_service = CommandService::new(input_handler).await?;

    spawn_discovery_service(discovery_service);
    spawn_status_server();

    log::info!("PointZerver ready - discovery and command services running");

    command_service.run().await
}

fn spawn_discovery_service(discovery_service: DiscoveryService) {
    tokio::spawn(async move {
        if let Err(e) = discovery_service.run().await {
            log::error!("Discovery loop error: {}", e);
        }
    });
}

fn spawn_status_server() {
    tokio::spawn(async move {
        if let Err(e) = status_server::run().await {
            log::error!("Status server error: {}", e);
        }
    });
}
