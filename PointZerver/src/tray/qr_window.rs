#[cfg(target_os = "linux")]
use gtk::{prelude::*, glib};
use tokio::sync::mpsc;
#[cfg(target_os = "linux")]
use qrcode::QrCode;
#[cfg(target_os = "linux")]
use image::Rgb;

#[cfg(target_os = "linux")]
static mut QR_WINDOW: Option<gtk::Window> = None;

pub async fn run_qr_window(mut rx: mpsc::UnboundedReceiver<super::QrData>) {
    #[cfg(target_os = "linux")]
    {
        while let Some(data) = rx.recv().await {
            let data_clone = data.clone();
            glib::idle_add_once(move || {
                show_qr_window(&data_clone);
            });
        }
    }
    
    #[cfg(not(target_os = "linux"))]
    {
        // On macOS/Windows, QR code display not yet implemented
        // For now, just consume the channel
        while let Some(_data) = rx.recv().await {
            // TODO: Implement native QR window for macOS/Windows
        }
    }
}

#[cfg(target_os = "linux")]
fn show_qr_window(data: &super::QrData) {
    unsafe {
        if let Some(ref window) = QR_WINDOW {
            window.destroy();
        }
    }
    
    let window = gtk::Window::new(gtk::WindowType::Toplevel);
    window.set_title("PointZ Server");
    window.set_default_size(350, 450);
    window.set_resizable(false);
    window.set_decorated(false);
    window.set_skip_taskbar_hint(true);
    window.set_keep_above(true);
    
    // Position window above system tray (bottom right)
    if let Some(display) = gtk::gdk::Display::default() {
        let monitor = display.primary_monitor()
            .or_else(|| display.monitor_at_point(0, 0));
        if let Some(monitor) = monitor {
            let geometry = monitor.geometry();
            let window_width = 350;
            let window_height = 450;
            let x = geometry.x() + geometry.width() - window_width - 20; // 20px from right edge
            let y = geometry.y() + geometry.height() - window_height - 60; // 60px above bottom (above tray)
            window.move_(x, y);
        }
    }
    
    let vbox = gtk::Box::new(gtk::Orientation::Vertical, 12);
    vbox.set_margin_top(16);
    vbox.set_margin_bottom(16);
    vbox.set_margin_start(16);
    vbox.set_margin_end(16);
    
    // Download link with close button on the right
    let window_clone = window.clone();
    let close_button = gtk::Button::new();
    let close_label = gtk::Label::new(Some("×"));
    close_label.set_markup("<span size='xx-large' weight='bold'>×</span>");
    close_button.add(&close_label);
    close_button.set_relief(gtk::ReliefStyle::None);
    close_button.set_opacity(0.6);
    close_button.set_size_request(32, 32);
    close_button.connect_clicked(move |_| {
        window_clone.hide();
    });
    
    let link = gtk::LinkButton::with_label(&data.download_url, "Download APK or use QR code");
    
    let download_box = gtk::Box::new(gtk::Orientation::Horizontal, 0);
    download_box.set_halign(gtk::Align::Fill);
    download_box.pack_start(&link, true, true, 0);
    download_box.pack_end(&close_button, false, false, 0);
    
    vbox.pack_start(&download_box, false, false, 0);
    
    if let Some(pixbuf) = generate_qr_pixbuf(&data.download_url) {
        let image = gtk::Image::from_pixbuf(Some(&pixbuf));
        vbox.pack_start(&image, false, false, 8);
    }
    
    let info_label = gtk::Label::new(Some("App will auto-discover this server on the same network"));
    info_label.set_opacity(0.6);
    info_label.set_line_wrap(true);
    info_label.set_justify(gtk::Justification::Center);
    vbox.pack_start(&info_label, false, false, 0);
    
    // Spacer to push bottom info to bottom
    let spacer = gtk::Box::new(gtk::Orientation::Vertical, 0);
    vbox.pack_start(&spacer, true, true, 0);
    
    // Bottom box with IP on left and version on right
    let bottom_box = gtk::Box::new(gtk::Orientation::Horizontal, 0);
    bottom_box.set_halign(gtk::Align::Fill);
    
    // IP label and feedback label container
    let ip_container = gtk::Box::new(gtk::Orientation::Horizontal, 4);
    
    let ip_label = gtk::Label::new(Some(&data.ip));
    ip_label.set_opacity(0.5);
    ip_label.set_halign(gtk::Align::Start);
    ip_label.set_selectable(true);
    
    // Feedback label for "Copied!" message
    let feedback_label = gtk::Label::new(Some(""));
    feedback_label.set_opacity(0.0);
    feedback_label.set_halign(gtk::Align::Start);
    
    // Make IP clickable to copy to clipboard using a button styled as text
    let ip_button = gtk::Button::new();
    ip_button.add(&ip_label);
    ip_button.set_relief(gtk::ReliefStyle::None);
    ip_button.set_can_focus(false);
    
    // Style the button to look like text
    let ip_to_copy = data.ip.clone();
    let feedback_label_clone = feedback_label.clone();
    ip_button.connect_clicked(move |_| {
        let clipboard = gtk::Clipboard::get(&gtk::gdk::SELECTION_CLIPBOARD);
        clipboard.set_text(&ip_to_copy);
        
        // Show "Copied!" feedback
        let feedback_for_timeout = feedback_label_clone.clone();
        feedback_label_clone.set_text("Copied!");
        feedback_label_clone.set_opacity(1.0);
        
        // Fade out after 1.5 seconds
        glib::timeout_add_local(std::time::Duration::from_millis(1500), move || {
            feedback_for_timeout.set_opacity(0.0);
            feedback_for_timeout.set_text("");
            glib::ControlFlow::Break
        });
    });
    
    ip_container.pack_start(&ip_button, false, false, 0);
    ip_container.pack_start(&feedback_label, false, false, 0);
    
    bottom_box.pack_start(&ip_container, false, false, 0);
    
    let version_label = gtk::Label::new(Some(&format!("v{}", env!("CARGO_PKG_VERSION"))));
    version_label.set_opacity(0.5);
    version_label.set_halign(gtk::Align::End);
    bottom_box.pack_end(&version_label, false, false, 0);
    
    vbox.pack_start(&bottom_box, false, false, 0);
    
    window.add(&vbox);
    window.show_all();
    window.present();
    
    // Close on click outside (focus out), escape key, or delete event
    window.connect_focus_out_event(|window, _| {
        window.hide();
        glib::Propagation::Stop
    });
    
    window.connect_delete_event(|window, _| {
        window.hide();
        glib::Propagation::Stop
    });
    
    window.connect_key_press_event(|window, event| {
        if event.keyval() == gtk::gdk::keys::constants::Escape {
            window.hide();
            glib::Propagation::Stop
        } else {
            glib::Propagation::Proceed
        }
    });
    
    unsafe {
        QR_WINDOW = Some(window);
    }
}

#[cfg(target_os = "linux")]
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

