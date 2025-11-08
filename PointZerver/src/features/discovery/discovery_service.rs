use anyhow::Result;
use tokio::net::UdpSocket;
use crate::domain::config::ServerConfig;

/// Service that handles server discovery via UDP broadcast
pub struct DiscoveryService {
    socket: UdpSocket,
}

impl DiscoveryService {
    /// Creates a new DiscoveryService bound to the discovery port
    pub async fn new() -> Result<Self> {
        let socket = UdpSocket::bind(format!("0.0.0.0:{}", ServerConfig::DISCOVERY_PORT)).await?;
        socket.set_broadcast(true)?;
        Ok(Self { socket })
    }

    /// Runs the discovery loop, responding to discovery requests indefinitely
    pub async fn run(&self) -> Result<()> {
        let mut buf = [0; ServerConfig::DISCOVERY_BUFFER_SIZE];
        
        loop {
            match self.socket.recv_from(&mut buf).await {
                Ok((size, addr)) => {
                    let request = String::from_utf8_lossy(&buf[..size]);
                    if request.trim() == ServerConfig::DISCOVER_MESSAGE {
                        let response = ServerConfig::SERVER_RESPONSE;
                        let _ = self.socket.send_to(response.as_bytes(), addr).await;
                    }
                }
                Err(e) => {
                    eprintln!("Discovery error: {}", e);
                }
            }
        }
    }
}

