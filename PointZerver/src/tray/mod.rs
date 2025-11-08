mod qr_window;

use anyhow::Result;
use tray_icon::menu::{Menu, MenuItem, MenuEvent};
use tray_icon::{TrayIconBuilder, TrayIconEvent};
use tokio::sync::mpsc;

#[cfg(target_os = "linux")]
use gtk::{self, glib};

pub struct TrayManager {
    #[cfg(not(target_os = "linux"))]
    _tray_icon: tray_icon::TrayIcon,
    _show_qr_tx: mpsc::UnboundedSender<QrData>,
}

#[derive(Clone)]
pub struct QrData {
    pub download_url: String,
    pub ip: String,
}

impl TrayManager {
    pub fn new() -> Result<Self> {
        let (show_qr_tx, show_qr_rx) = mpsc::unbounded_channel();
        
        #[cfg(target_os = "linux")]
        {
            let show_qr_tx_for_tray = show_qr_tx.clone();
            std::thread::spawn(move || {
                if gtk::init().is_err() {
                    return;
                }
                
                let show_qr_item = MenuItem::with_id(
                    "show_qr",
                    "Show QR Code",
                    true,
                    None,
                );
                
                let quit_item = MenuItem::with_id(
                    "quit",
                    "Quit",
                    true,
                    None,
                );
                
                let menu = match Menu::with_items(&[&show_qr_item, &quit_item]) {
                    Ok(m) => m,
                    Err(_) => return,
                };
                
                let icon = create_tray_icon();
                
                let tray_icon = match TrayIconBuilder::new()
                    .with_menu(Box::new(menu))
                    .with_tooltip("PointZ Server")
                    .with_icon(icon)
                    .with_menu_on_left_click(false)
                    .build()
                {
                    Ok(ti) => ti,
                    Err(_) => return,
                };
                
                let show_qr_tx_for_handler = show_qr_tx_for_tray.clone();
                let show_qr_tx_for_menu = show_qr_tx_for_tray.clone();
                
                // Handle menu item clicks via MenuEvent
                let menu_receiver = MenuEvent::receiver();
                let show_qr_tx_menu = show_qr_tx_for_menu.clone();
                glib::timeout_add_local(std::time::Duration::from_millis(100), move || {
                    while let Ok(event) = menu_receiver.try_recv() {
                        match event.id.as_ref() {
                            "quit" => {
                                std::process::exit(0);
                            }
                            "show_qr" => {
                                let _ = show_qr_tx_menu.send(QrData {
                                    download_url: "https://github.com/KMRH47/pointZ-new/releases/latest".to_string(),
                                    ip: get_local_ip_string(),
                                });
                            }
                            _ => {}
                        }
                    }
                    glib::ControlFlow::Continue
                });
                
                // Handle tray icon clicks via TrayIconEvent
                let tray_event_receiver = TrayIconEvent::receiver();
                glib::timeout_add_local(std::time::Duration::from_millis(100), move || {
                    while let Ok(event) = tray_event_receiver.try_recv() {
                        if matches!(event.click_type, tray_icon::ClickType::Left | tray_icon::ClickType::Right) {
                            let _ = show_qr_tx_for_handler.send(QrData {
                                download_url: "https://github.com/KMRH47/pointZ-new/releases/latest".to_string(),
                                ip: get_local_ip_string(),
                            });
                        }
                    }
                    glib::ControlFlow::Continue
                });
                
                std::thread::spawn(move || {
                    let rt = tokio::runtime::Runtime::new().unwrap();
                    rt.block_on(async {
                        qr_window::run_qr_window(show_qr_rx).await;
                    });
                });
                
                // Keep tray icon alive
                std::mem::forget(tray_icon);
                gtk::main();
            });
            
            std::thread::sleep(std::time::Duration::from_millis(100));
            
            return Ok(Self {
                _show_qr_tx: show_qr_tx,
            });
        }
        
        #[cfg(not(target_os = "linux"))]
        {
            let show_qr_item = MenuItem::with_id(
                "show_qr",
                "Show QR Code",
                true,
                None,
            );
            
            let quit_item = MenuItem::with_id(
                "quit",
                "Quit",
                true,
                None,
            );
            
            let menu = Menu::with_items(&[
                &show_qr_item,
                &quit_item,
            ])?;
            
            let icon = create_tray_icon();
            
            let tray_icon = TrayIconBuilder::new()
                .with_menu(Box::new(menu))
                .with_tooltip("PointZ Server")
                .with_icon(icon)
                .with_menu_on_left_click(false)
                .build()?;
            
            let show_qr_tx_for_handler = show_qr_tx.clone();
            let show_qr_tx_for_menu = show_qr_tx.clone();
            
            // Handle menu item clicks via MenuEvent
            let menu_receiver = MenuEvent::receiver();
            std::thread::spawn(move || {
                while let Ok(event) = menu_receiver.recv() {
                    match event.id.as_ref() {
                        "quit" => {
                            std::process::exit(0);
                        }
                        "show_qr" => {
                            let _ = show_qr_tx_for_menu.send(QrData {
                                download_url: "https://github.com/KMRH47/pointZ-new/releases/latest".to_string(),
                                ip: get_local_ip_string(),
                            });
                        }
                        _ => {}
                    }
                }
            });
            
            // Handle tray icon clicks via TrayIconEvent
            let tray_event_receiver = TrayIconEvent::receiver();
            std::thread::spawn(move || {
                while let Ok(event) = tray_event_receiver.recv() {
                    if matches!(event.click_type, tray_icon::ClickType::Left | tray_icon::ClickType::Right) {
                        let _ = show_qr_tx_for_handler.send(QrData {
                            download_url: "https://github.com/KMRH47/pointZ-new/releases/latest".to_string(),
                            ip: get_local_ip_string(),
                        });
                    }
                }
            });
            
            std::thread::spawn(move || {
                let rt = tokio::runtime::Runtime::new().unwrap();
                rt.block_on(async {
                    qr_window::run_qr_window(show_qr_rx).await;
                });
            });
            
            return Ok(Self {
                _tray_icon: tray_icon,
                _show_qr_tx: show_qr_tx,
            });
        }
        
        Ok(Self {
            _show_qr_tx: show_qr_tx,
        })
    }
    
}

fn get_local_ip_string() -> String {
    crate::utils::get_local_ip()
        .map(|ip| ip.to_string())
        .unwrap_or_else(|| "localhost".to_string())
}

fn create_tray_icon() -> tray_icon::Icon {
    const ICON_SIZE: u32 = 32;
    let mut icon_data = Vec::new();
    
    for y in 0..ICON_SIZE {
        for x in 0..ICON_SIZE {
            let dx = x as f32 - ICON_SIZE as f32 / 2.0;
            let dy = y as f32 - ICON_SIZE as f32 / 2.0;
            let dist = (dx * dx + dy * dy).sqrt();
            
            let (r, g, b, a) = if dist < ICON_SIZE as f32 / 2.0 - 2.0 {
                if dist < 4.0 {
                    (100, 150, 255, 255)
                } else {
                    (80, 130, 235, 255)
                }
            } else {
                (0, 0, 0, 0)
            };
            
            icon_data.push(r);
            icon_data.push(g);
            icon_data.push(b);
            icon_data.push(a);
        }
    }
    
    tray_icon::Icon::from_rgba(icon_data, ICON_SIZE, ICON_SIZE)
        .expect("Failed to create icon")
}

