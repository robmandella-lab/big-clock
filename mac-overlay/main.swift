// Big Clock — native Mac wrapper for the big-clock web app.
// A floating, resizable, optionally see-through window with the clock,
// timer, stopwatch, and teleprompter. Background transparency is toggled
// inside the app: Script panel -> Background -> See-through / Solid.
//
// Window controls live in the 🕐 menu-bar icon and the normal title bar.
import Cocoa
import WebKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    var statusItem: NSStatusItem!
    var savedFrame: NSRect?          // frame to restore when leaving full screen

    let appURL = URL(string: "https://robmandella-lab.github.io/big-clock/?transparent")!

    func applicationDidFinishLaunching(_ note: Notification) {
        buildMainMenu()

        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let w: CGFloat = min(900, screen.width * 0.7)
        let h: CGFloat = min(600, screen.height * 0.7)
        let rect = NSRect(x: screen.midX - w / 2, y: screen.midY - h / 2, width: w, height: h)

        window = NSWindow(contentRect: rect,
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Big Clock"
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.minSize = NSSize(width: 320, height: 200)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false   // red button hides; Dock/menu icon reopens

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
        statusItem.button?.title = "🕐"
        let menu = NSMenu()
        menu.addItem(makeItem("Show Big Clock Window", #selector(showWindow), "o"))
        menu.addItem(makeItem("Full Screen On/Off", #selector(toggleFullOverlay), "f"))
        menu.addItem(.separator())
        menu.addItem(makeItem("Click-Through (use apps underneath)", #selector(toggleClickThrough(_:)), "t"))
        menu.addItem(makeItem("Hide from Screen Recording", #selector(toggleCapture(_:)), "h"))
        menu.addItem(.separator())
        menu.addItem(makeItem("Reload", #selector(reloadPage), "r"))
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Big Clock",
                              action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        statusItem.menu = menu
    }

    // Standard app + Edit menus so copy/paste shortcuts work in the web view.
    func buildMainMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Quit Big Clock",
                                   action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appItem.submenu = appMenu

        let editItem = NSMenuItem()
        main.addItem(editItem)
        let edit = NSMenu(title: "Edit")
        edit.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        edit.addItem(NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
        edit.addItem(.separator())
        edit.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        edit.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        edit.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        edit.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editItem.submenu = edit

        NSApp.mainMenu = main
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

    // Clicking the Dock icon brings the window back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows { showWindow() }
        return true
    }

    // "Full screen" = stretch over the current screen while remaining an
    // overlay above other apps (NOT macOS native full screen, which would
    // move to its own Space). The menu bar stays clickable throughout.
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
app.setActivationPolicy(.regular) // real app: Dock icon, Cmd-Tab, Launchpad
app.run()
