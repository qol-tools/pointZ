use serde::Deserialize;

/// Mouse button type alias for clarity
pub type MouseButton = u8;

/// Command sent from client to server
#[derive(Deserialize, Debug, Clone)]
#[serde(tag = "type")]
pub enum Command {
    MouseMove { x: f64, y: f64 },
    MouseClick { button: MouseButton },
    MouseDown { button: MouseButton },
    MouseUp { button: MouseButton },
    MouseScroll { delta_x: f64, delta_y: f64 },
    KeyPress { key: String },
    KeyRelease { key: String },
}

