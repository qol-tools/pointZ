#[cfg(unix)]
mod unix;
#[cfg(windows)]
mod windows;

use anyhow::Result;
use crate::domain::models::Command;

#[cfg(unix)]
use unix::InputHandlerImpl;

#[cfg(windows)]
use windows::InputHandlerImpl;

/// Handles input commands and delegates to platform-specific implementations
pub struct InputHandler {
    inner: InputHandlerImpl,
}

impl InputHandler {
    /// Creates a new InputHandler with platform-specific implementation
    pub fn new() -> Result<Self> {
        Ok(Self {
            inner: InputHandlerImpl::new()?,
        })
    }
    
    /// Processes a command and executes the corresponding input action
    pub async fn handle_command(&self, command: Command) -> Result<()> {
        match command {
            Command::MouseMove { x, y } => self.inner.mouse_move(x, y).await,
            Command::MouseClick { button } => self.inner.mouse_click(button).await,
            Command::MouseDown { button } => self.inner.mouse_down(button).await,
            Command::MouseUp { button } => self.inner.mouse_up(button).await,
            Command::MouseScroll { delta_x, delta_y } => self.inner.mouse_scroll(delta_x, delta_y).await,
            Command::KeyPress { key } => self.inner.key_press(&key).await,
            Command::KeyRelease { key } => self.inner.key_release(&key).await,
        }
    }
}

#[async_trait::async_trait]
pub(crate) trait InputHandlerTrait: Send + Sync {
    async fn mouse_move(&self, x: f64, y: f64) -> Result<()>;
    async fn mouse_click(&self, button: u8) -> Result<()>;
    async fn mouse_down(&self, button: u8) -> Result<()>;
    async fn mouse_up(&self, button: u8) -> Result<()>;
    async fn mouse_scroll(&self, delta_x: f64, delta_y: f64) -> Result<()>;
    async fn key_press(&self, key: &str) -> Result<()>;
    async fn key_release(&self, key: &str) -> Result<()>;
}

