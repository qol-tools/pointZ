mod qr_window;

use anyhow::Result;
use tray_icon::menu::{Menu, MenuItem, MenuEvent};
use tray_icon::TrayIconBuilder;
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
                
                let icon = create_tray_icon();
                
                // On Linux, TrayIconEvent is unsupported - we can only use MenuEvent
                // So we provide "Show QR Code" as a menu item instead of left-click
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
                
                let tray_icon = match TrayIconBuilder::new()
                    .with_menu(Box::new(menu))
                    .with_tooltip("PointZ Server")
                    .with_icon(icon)
                    .build()
                {
                    Ok(ti) => ti,
                    Err(_) => return,
                };
                
                let show_qr_tx_for_menu = show_qr_tx_for_tray.clone();
                
                // On Linux, only MenuEvent works - TrayIconEvent is unsupported
                let menu_receiver = MenuEvent::receiver();
                glib::timeout_add_local(std::time::Duration::from_millis(100), move || {
                    while let Ok(event) = menu_receiver.try_recv() {
                        match event.id.as_ref() {
                            "show_qr" => {
                                let _ = show_qr_tx_for_menu.send(QrData {
                                    download_url: "https://github.com/KMRH47/pointZ-new/releases/latest/download/pointz-app.apk".to_string(),
                                    ip: get_local_ip_string(),
                                });
                            }
                            "quit" => {
                                std::process::exit(0);
                            }
                            _ => {}
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

            Ok(Self {
                _show_qr_tx: show_qr_tx,
            })
        }
        
        #[cfg(not(target_os = "linux"))]
        {
            let quit_item = MenuItem::with_id(
                "quit",
                "Quit",
                true,
                None,
            );
            
            let menu = Menu::with_items(&[&quit_item])?;
            
            let icon = create_tray_icon();
            
            let tray_icon = TrayIconBuilder::new()
                .with_menu(Box::new(menu))
                .with_tooltip("PointZ Server")
                .with_icon(icon)
                .with_menu_on_left_click(false)
                .build()?;
            
            let show_qr_tx_for_handler = show_qr_tx.clone();
            
            // Handle menu item clicks via MenuEvent
            let menu_receiver = MenuEvent::receiver();
            std::thread::spawn(move || {
                while let Ok(event) = menu_receiver.recv() {
                    match event.id.as_ref() {
                        "quit" => {
                            std::process::exit(0);
                        }
                        _ => {}
                    }
                }
            });
            
            // Handle tray icon clicks via TrayIconEvent
            // Left click: Open QR UI directly
            // Right click: Show context menu (handled automatically by tray-icon)
            let tray_event_receiver = TrayIconEvent::receiver();
            std::thread::spawn(move || {
                while let Ok(event) = tray_event_receiver.recv() {
                    if matches!(event.click_type, tray_icon::ClickType::Left) {
                        let _ = show_qr_tx_for_handler.send(QrData {
                            download_url: "https://github.com/KMRH47/pointZ-new/releases/latest/download/pointz-app.apk".to_string(),
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
    }
    
}

fn get_local_ip_string() -> String {
    crate::utils::get_local_ip()
        .map(|ip| ip.to_string())
        .unwrap_or_else(|| "localhost".to_string())
}


fn create_tray_icon() -> tray_icon::Icon {
    const ICON_SIZE: u32 = 32;
    
    load_app_icon(ICON_SIZE)
        .or_else(|| create_fallback_icon(ICON_SIZE))
        .expect("Failed to create tray icon")
}

fn load_app_icon(size: u32) -> Option<tray_icon::Icon> {
    let icon_paths = get_icon_paths();
    let candidate_paths = generate_candidate_paths();
    
    candidate_paths
        .iter()
        .flat_map(|base_path| {
            icon_paths.iter().map(move |rel_path| base_path.join(rel_path))
        })
        .find_map(|path| load_and_convert_icon(&path, size))
}

fn get_icon_paths() -> Vec<&'static str> {
    vec![
        "PointZ/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png",
        "PointZ/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png",
        "PointZ/android/app/src/main/res/mipmap-hdpi/ic_launcher.png",
        "PointZ/android/app/src/main/res/mipmap-mdpi/ic_launcher.png",
    ]
}

fn generate_candidate_paths() -> Vec<std::path::PathBuf> {
    let mut paths = Vec::new();
    
    if let Ok(current_dir) = std::env::current_dir() {
        paths.push(current_dir);
    }
    
    if let Some(parent) = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).parent() {
        paths.push(parent.to_path_buf());
    }
    
    paths
}

fn load_and_convert_icon(path: &std::path::Path, size: u32) -> Option<tray_icon::Icon> {
    let img = image::open(path).ok()?;
    let rgba = img.to_rgba8();
    let resized = image::imageops::resize(
        &rgba,
        size,
        size,
        image::imageops::FilterType::Lanczos3,
    );
    
    let icon_data: Vec<u8> = resized
        .pixels()
        .flat_map(|pixel| [pixel[0], pixel[1], pixel[2], pixel[3]])
        .collect();
    
    tray_icon::Icon::from_rgba(icon_data, size, size).ok()
}

fn create_fallback_icon(size: u32) -> Option<tray_icon::Icon> {
    let icon_data: Vec<u8> = (0..size)
        .flat_map(|y| {
            (0..size).flat_map(move |x| {
                let pixel = calculate_fallback_pixel(x, y, size);
                [pixel.0, pixel.1, pixel.2, pixel.3]
            })
        })
        .collect();
    
    tray_icon::Icon::from_rgba(icon_data, size, size).ok()
}

fn calculate_fallback_pixel(x: u32, y: u32, size: u32) -> (u8, u8, u8, u8) {
    let center = size as f32 / 2.0;
    let dx = x as f32 - center;
    let dy = y as f32 - center;
    let distance = (dx * dx + dy * dy).sqrt();
    let radius = center - 2.0;
    
    if distance < radius {
        if distance < 4.0 {
            (100, 150, 255, 255)
        } else {
            (80, 130, 235, 255)
        }
    } else {
        (0, 0, 0, 0)
    }
}

