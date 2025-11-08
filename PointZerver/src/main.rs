mod domain;
mod features;
mod input;
mod utils;

use anyhow::Result;
use crate::features::discovery::discovery_service::DiscoveryService;
use crate::features::command::command_service::CommandService;
use crate::utils::{get_local_ip, print_qr_code};

#[tokio::main]
async fn main() -> Result<()> {
    let input_handler = input::InputHandler::new()?;
    
    let discovery_service = DiscoveryService::new().await?;
    let command_service = CommandService::new(input_handler).await?;
    
    // Get local IP and print QR code
    let local_ip = get_local_ip()
        .map(|ip| ip.to_string())
        .unwrap_or_else(|| "localhost".to_string());
    
    // TODO: Update with actual download URL (GitHub releases, app store, etc.)
    let download_url = "https://github.com/KMRH47/pointZ-new/releases/latest";
    print_qr_code(download_url, &local_ip);
    
    tokio::spawn(async move {
        if let Err(e) = discovery_service.run().await {
            eprintln!("Discovery loop error: {}", e);
        }
    });
    
    command_service.run().await
}
