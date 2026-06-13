// Teleprompter Overlay — a transparent, always-on-top, resizable window
// showing the big-clock app (teleprompter/clock/timer) over other apps.
//
// Starts as a normal 900x600 window you can move and resize. Full screen
// is an opt-in toggle (⌘F from the 📜 menu-bar icon), as is click-through.
import Cocoa
import WebKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    var statusItem: NSStatusItem!
    var savedFrame: NSRect?          // frame to restore when leaving full screen

    let appURL = URL(string: "https://robmandella-lab.github.io/big-clock/?transparent")!

    func applicationDidFinishLaunching(_ note: Notification) {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let w: CGFloat = min(900, screen.width * 0.7)
        let h: CGFloat = min(600, screen.height * 0.7)
        let rect = NSRect(x: screen.midX - w / 2, y: screen.midY - h / 2, width: w, height: h)

        window = NSWindow(contentRect: rect,
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Teleprompter Overlay"
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.minSize = NSSize(width: 320, height: 200)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false   // red button hides; reopen from 📜 menu

        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: window.contentLayoutRect, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        if #available(macOS 12.0, *) { webView.underPageBackgroundColor = .clear }
        webView.autoresizingMask = [.width, .height]
        webView.load(URLRequest(url: appURL))

        window.contentView = webView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "📜"
        let menu = NSMenu()

        menu.addItem(makeItem("Show Overlay Window", #selector(showWindow), "o"))
        menu.addItem(makeItem("Full Screen On/Off", #selector(toggleFullOverlay), "f"))
        menu.addItem(.separator())
        menu.addItem(makeItem("Click-Through (use apps underneath)", #selector(toggleClickThrough(_:)), "t"))
        menu.addItem(makeItem("Hide from Screen Recording", #selector(toggleCapture(_:)), "h"))
        menu.addItem(.separator())
        menu.addItem(makeItem("Reload", #selector(reloadPage), "r"))
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Teleprompter Overlay",
                              action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        statusItem.menu = menu
    }

    func makeItem(_ title: String, _ action: Selector, _ key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // "Full screen" = stretch over the current screen while staying an
    // overlay on top of other apps (NOT macOS native full screen, which
    // would move to its own Space and defeat the purpose). The menu bar
    // stays clickable, so 📜 is always the way back out.
    @objc func toggleFullOverlay() {
        if let saved = savedFrame {
            window.setFrame(saved, display: true, animate: true)
            savedFrame = nil
        } else {
            savedFrame = window.frame
            let target = window.screen ?? NSScreen.main
            if let frame = target?.frame {
                window.setFrame(frame, display: true, animate: true)
            }
        }
    }

    @objc func toggleClickThrough(_ item: NSMenuItem) {
        window.ignoresMouseEvents.toggle()
        item.state = window.ignoresMouseEvents ? .on : .off
    }

    @objc func toggleCapture(_ item: NSMenuItem) {
        window.sharingType = (window.sharingType == .none) ? .readOnly : .none
        item.state = (window.sharingType == .none) ? .on : .off
    }

    @objc func reloadPage() { webView.reload() }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // menu-bar only, no Dock icon
app.run()
