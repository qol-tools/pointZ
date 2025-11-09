use cocoa::appkit::{NSWindow, NSWindowStyleMask, NSBackingStoreType};
use cocoa::base::{id, nil, YES, NO};
use cocoa::foundation::{NSRect, NSPoint, NSSize, NSString, NSAutoreleasePool};
use qrcode::QrCode;
use image::{Rgb, RgbaImage};
use objc::{msg_send, sel, sel_impl, class};

const WINDOW_WIDTH: f64 = 350.0;
const WINDOW_HEIGHT: f64 = 450.0;
const QR_SIZE: u32 = 300;

/// Show the QR code window on macOS
pub fn show_qr_window(data: &crate::tray::QrData) {
    let download_url = data.download_url.clone();
    let ip = data.ip.clone();

    // All Cocoa UI operations must happen on the main thread
    // Use Grand Central Dispatch to execute on main queue
    dispatch::Queue::main().exec_async(move || {
        unsafe {
            let _pool = NSAutoreleasePool::new(nil);

            let window = create_window();

            if let Some(qr_image) = generate_qr_image(&download_url) {
                set_window_content(window, &qr_image, &ip);
            }

            // Activate the application so the window can appear
            use cocoa::appkit::NSApp;
            let app = NSApp();
            let _: () = msg_send![app, activateIgnoringOtherApps: YES];

            window.makeKeyAndOrderFront_(nil);
        }
    });
}

/// Create a new NSWindow
unsafe fn create_window() -> id {
    let style_mask = NSWindowStyleMask::NSTitledWindowMask
        | NSWindowStyleMask::NSClosableWindowMask
        | NSWindowStyleMask::NSMiniaturizableWindowMask;

    // Position window in center of screen
    let screen_frame = get_screen_frame();
    let x = (screen_frame.size.width - WINDOW_WIDTH) / 2.0;
    let y = (screen_frame.size.height - WINDOW_HEIGHT) / 2.0;

    let rect = NSRect::new(
        NSPoint::new(x, y),
        NSSize::new(WINDOW_WIDTH, WINDOW_HEIGHT),
    );

    let window = NSWindow::alloc(nil).initWithContentRect_styleMask_backing_defer_(
        rect,
        style_mask,
        NSBackingStoreType::NSBackingStoreBuffered,
        false,
    );

    let title = NSString::alloc(nil).init_str("PointZ Server - QR Code");
    window.setTitle_(title);
    window.setReleasedWhenClosed_(false);

    window
}

/// Get the main screen frame
unsafe fn get_screen_frame() -> NSRect {
    use cocoa::appkit::NSScreen;
    let screens = NSScreen::screens(nil);
    let main_screen: id = msg_send![screens, objectAtIndex: 0usize];
    NSScreen::frame(main_screen)
}

/// Set window content with QR code and info
unsafe fn set_window_content(window: id, qr_image: &RgbaImage, ip: &str) {
    use cocoa::appkit::{NSView, NSTextField, NSImageView};

    // Create main content view
    let content_view: id = msg_send![class!(NSView), alloc];
    let content_rect = NSRect::new(
        NSPoint::new(0.0, 0.0),
        NSSize::new(WINDOW_WIDTH, WINDOW_HEIGHT),
    );
    let _: () = msg_send![content_view, initWithFrame: content_rect];

    // Create and add link label at top
    let link_label = create_label("Download APK or use QR code", 20.0, WINDOW_HEIGHT - 40.0, WINDOW_WIDTH - 40.0, 30.0);
    let _: () = msg_send![content_view, addSubview: link_label];

    // Create NSImage from QR code
    let ns_image = create_ns_image_from_rgba(qr_image);

    // Create image view for QR code
    let image_view: id = msg_send![class!(NSImageView), alloc];
    let image_rect = NSRect::new(
        NSPoint::new((WINDOW_WIDTH - QR_SIZE as f64) / 2.0, 90.0),
        NSSize::new(QR_SIZE as f64, QR_SIZE as f64),
    );
    let _: () = msg_send![image_view, initWithFrame: image_rect];
    let _: () = msg_send![image_view, setImage: ns_image];
    let _: () = msg_send![content_view, addSubview: image_view];

    // Create IP label at bottom
    let ip_text = format!("{}", ip);
    let ip_label = create_label(&ip_text, 20.0, 50.0, WINDOW_WIDTH - 40.0, 30.0);
    let _: () = msg_send![content_view, addSubview: ip_label];

    // Create info label
    let info_label = create_label("App will auto-discover this server on the same network", 20.0, 20.0, WINDOW_WIDTH - 40.0, 30.0);
    let _: () = msg_send![content_view, addSubview: info_label];

    window.setContentView_(content_view);
}

/// Create a label (NSTextField) with given text and position
unsafe fn create_label(text: &str, x: f64, y: f64, width: f64, height: f64) -> id {
    let label: id = msg_send![class!(NSTextField), alloc];
    let frame = NSRect::new(NSPoint::new(x, y), NSSize::new(width, height));
    let _: () = msg_send![label, initWithFrame: frame];

    let ns_text = NSString::alloc(nil).init_str(text);
    let _: () = msg_send![label, setStringValue: ns_text];
    let _: () = msg_send![label, setBezeled: NO];
    let _: () = msg_send![label, setDrawsBackground: NO];
    let _: () = msg_send![label, setEditable: NO];
    let _: () = msg_send![label, setSelectable: NO];
    let _: () = msg_send![label, setAlignment: 1i32]; // Center alignment

    label
}

/// Create NSImage from RGBA image data
unsafe fn create_ns_image_from_rgba(rgba_image: &RgbaImage) -> id {
    use core_foundation::base::TCFType;
    use core_foundation::data::CFData;

    let (width, height) = rgba_image.dimensions();
    let raw_data = rgba_image.as_raw();

    // Create NSBitmapImageRep from data
    let bitmap_rep: id = msg_send![class!(NSBitmapImageRep), alloc];
    let color_space_name = NSString::alloc(nil).init_str("NSDeviceRGBColorSpace");

    let bitmap_rep: id = msg_send![
        bitmap_rep,
        initWithBitmapDataPlanes: std::ptr::null_mut::<*mut u8>()
        pixelsWide: width as i64
        pixelsHigh: height as i64
        bitsPerSample: 8i64
        samplesPerPixel: 4i64
        hasAlpha: YES
        isPlanar: NO
        colorSpaceName: color_space_name
        bytesPerRow: (width * 4) as i64
        bitsPerPixel: 32i64
    ];

    // Copy pixel data
    let bitmap_data: *mut u8 = msg_send![bitmap_rep, bitmapData];
    std::ptr::copy_nonoverlapping(raw_data.as_ptr(), bitmap_data, raw_data.len());

    // Create NSImage and add bitmap representation
    let ns_image: id = msg_send![class!(NSImage), alloc];
    let size = NSSize::new(width as f64, height as f64);
    let _: () = msg_send![ns_image, initWithSize: size];
    let _: () = msg_send![ns_image, addRepresentation: bitmap_rep];

    ns_image
}

/// Generate QR code as RGBA image
fn generate_qr_image(data: &str) -> Option<RgbaImage> {
    let qr = QrCode::new(data).ok()?;
    let rgb_image = qr.render::<Rgb<u8>>()
        .max_dimensions(QR_SIZE, QR_SIZE)
        .build();

    // Convert RGB to RGBA
    let (width, height) = rgb_image.dimensions();
    let mut rgba_image = RgbaImage::new(width, height);

    for (x, y, pixel) in rgb_image.enumerate_pixels() {
        rgba_image.put_pixel(x, y, image::Rgba([pixel[0], pixel[1], pixel[2], 255]));
    }

    Some(rgba_image)
}
