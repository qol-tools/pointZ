#[cfg(unix)]
use gtk::{prelude::*, glib};
use tokio::sync::mpsc;
use qrcode::QrCode;
use image::Rgb;

#[cfg(unix)]
static mut QR_WINDOW: Option<gtk::Window> = None;

pub async fn run_qr_window(mut rx: mpsc::UnboundedReceiver<super::QrData>) {
    #[cfg(unix)]
    {
        while let Some(data) = rx.recv().await {
            let data_clone = data.clone();
            glib::idle_add_once(move || {
                show_qr_window(&data_clone);
            });
        }
    }
    
    #[cfg(not(unix))]
    {
        let _ = rx;
    }
}

#[cfg(unix)]
fn show_qr_window(data: &super::QrData) {
    unsafe {
        if let Some(ref window) = QR_WINDOW {
            window.destroy();
        }
    }
    
    let window = gtk::Window::new(gtk::WindowType::Toplevel);
    window.set_title("PointZ Server - QR Code");
    window.set_default_size(400, 550);
    window.set_resizable(false);
    
    let vbox = gtk::Box::new(gtk::Orientation::Vertical, 10);
    vbox.set_margin_top(20);
    vbox.set_margin_bottom(20);
    vbox.set_margin_start(20);
    vbox.set_margin_end(20);
    
    let title = gtk::Label::new(Some("<b>PointZ Server</b>"));
    title.set_use_markup(true);
    vbox.pack_start(&title, false, false, 0);
    
    let ip_label = gtk::Label::new(Some(&format!("Server IP: {}", data.ip)));
    vbox.pack_start(&ip_label, false, false, 0);
    
    let port_label = gtk::Label::new(Some("Ports: Discovery=45454, Command=45455"));
    vbox.pack_start(&port_label, false, false, 0);
    
    let separator1 = gtk::Separator::new(gtk::Orientation::Horizontal);
    vbox.pack_start(&separator1, false, false, 5);
    
    let scan_label = gtk::Label::new(Some("Scan QR code to download app:"));
    vbox.pack_start(&scan_label, false, false, 0);
    
    if let Some(pixbuf) = generate_qr_pixbuf(&data.download_url) {
        let image = gtk::Image::from_pixbuf(Some(&pixbuf));
        vbox.pack_start(&image, false, false, 10);
    }
    
    let separator2 = gtk::Separator::new(gtk::Orientation::Horizontal);
    vbox.pack_start(&separator2, false, false, 5);
    
    let manual_label = gtk::Label::new(Some("Or download manually:"));
    vbox.pack_start(&manual_label, false, false, 0);
    
    let link = gtk::LinkButton::with_label(&data.download_url, &data.download_url);
    vbox.pack_start(&link, false, false, 0);
    
    let info_label = gtk::Label::new(Some("App will auto-discover this server on the same network."));
    vbox.pack_start(&info_label, false, false, 0);
    
    window.add(&vbox);
    window.show_all();
    window.present();
    
    window.connect_delete_event(|window, _| {
        window.hide();
        glib::Propagation::Stop
    });
    
    unsafe {
        QR_WINDOW = Some(window);
    }
}

#[cfg(unix)]
fn generate_qr_pixbuf(data: &str) -> Option<gtk::gdk_pixbuf::Pixbuf> {
    let qr = QrCode::new(data).ok()?;
    let qr_image = qr.render::<Rgb<u8>>()
        .max_dimensions(300, 300)
        .build();
    
    let (width, height) = qr_image.dimensions();
    let bytes: Vec<u8> = qr_image
        .pixels()
        .flat_map(|p| vec![p[0], p[1], p[2], 255])
        .collect();
    
    Some(gtk::gdk_pixbuf::Pixbuf::from_bytes(
        &glib::Bytes::from(&bytes),
        gtk::gdk_pixbuf::Colorspace::Rgb,
        true,
        8,
        width as i32,
        height as i32,
        (width * 4) as i32,
    ))
}

