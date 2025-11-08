use serde::Deserialize;

/// Mouse button type alias for clarity
pub type MouseButton = u8;

/// Modifier keys state
#[derive(Deserialize, Debug, Clone, Default)]
pub struct ModifierKeys {
    #[serde(default)]
    pub ctrl: bool,
    #[serde(default)]
    pub alt: bool,
    #[serde(default)]
    pub shift: bool,
    #[serde(default)]
    pub meta: bool,
}

/// Command sent from client to server
#[derive(Deserialize, Debug, Clone)]
#[serde(tag = "type")]
pub enum Command {
    MouseMove { x: f64, y: f64 },
    MouseClick { button: MouseButton },
    MouseDown { button: MouseButton },
    MouseUp { button: MouseButton },
    MouseScroll { delta_x: f64, delta_y: f64 },
    KeyPress { key: String, #[serde(default)] modifiers: ModifierKeys },
    KeyRelease { key: String, #[serde(default)] modifiers: ModifierKeys },
    ModifierPress { modifier: String },
    ModifierRelease { modifier: String },
}

