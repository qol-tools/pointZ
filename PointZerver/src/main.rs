mod domain;
mod features;
mod input;

use anyhow::Result;
use crate::features::discovery::discovery_service::DiscoveryService;
use crate::features::command::command_service::CommandService;

#[tokio::main]
async fn main() -> Result<()> {
    let input_handler = input::InputHandler::new()?;
    
    let discovery_service = DiscoveryService::new().await?;
    let command_service = CommandService::new(input_handler).await?;
    
    tokio::spawn(async move {
        if let Err(e) = discovery_service.run().await {
            eprintln!("Discovery loop error: {}", e);
        }
    });
    
    command_service.run().await
}
