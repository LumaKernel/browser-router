import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private let urlStore = URLStore()

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:replyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()

        let contentView = ContentView(urlStore: urlStore)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 200),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.title = "URL Catcher"
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }

    private func setupMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit URL Catcher", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            window?.makeKeyAndOrderFront(nil)
        }
        return true
    }

    @objc func handleGetURL(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue else {
            return
        }
        urlStore.addURL(urlString)
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeKeyAndOrderFront(nil)
            NSApp.activate()
        }
    }
}

struct BrowserInfo: Identifiable {
    let id: String // bundle identifier
    let name: String
    let icon: NSImage

    static func detectBrowsers() -> [BrowserInfo] {
        let myBundleId = (Bundle.main.bundleIdentifier ?? "").lowercased()
        let httpsURL = URL(string: "https://example.com")!
        let appURLs = NSWorkspace.shared.urlsForApplications(toOpen: httpsURL)

        var seen = Set<String>()
        return appURLs.compactMap { appURL -> BrowserInfo? in
            guard let bundle = Bundle(url: appURL),
                  let bundleId = bundle.bundleIdentifier?.lowercased() else { return nil }
            guard bundleId != myBundleId else { return nil }
            guard seen.insert(bundleId).inserted else { return nil }
            let name = FileManager.default.displayName(atPath: appURL.path)
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            icon.size = NSSize(width: 16, height: 16)
            return BrowserInfo(id: bundleId, name: name, icon: icon)
        }
    }

    func open(url: String) {
        guard let url = URL(string: url),
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else { return }
        NSWorkspace.shared.open(
            [url],
            withApplicationAt: appURL,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }
}

class URLStore: ObservableObject {
    @Published var urls: [URLEntry] = []

    struct URLEntry: Identifiable {
        let id = UUID()
        let url: String
        let timestamp: Date
    }

    func addURL(_ url: String) {
        let entry = URLEntry(url: url, timestamp: Date())
        DispatchQueue.main.async {
            self.urls.insert(entry, at: 0)
        }
    }
}

struct ContentView: View {
    @ObservedObject var urlStore: URLStore
    @State private var copiedId: UUID?
    private let browsers = BrowserInfo.detectBrowsers()

    var body: some View {
        VStack(spacing: 0) {
            if urlStore.urls.isEmpty {
                Spacer()
                Text("Waiting for URLs...")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List(urlStore.urls) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.url)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .lineLimit(2)
                        Text(entry.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 6) {
                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(entry.url, forType: .string)
                                copiedId = entry.id
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    if copiedId == entry.id {
                                        copiedId = nil
                                    }
                                }
                            }) {
                                Text(copiedId == entry.id ? "Copied!" : "Copy")
                                    .frame(width: 54)
                            }
                            .buttonStyle(.borderedProminent)

                            ForEach(browsers) { browser in
                                Button(action: {
                                    browser.open(url: entry.url)
                                }) {
                                    HStack(spacing: 3) {
                                        Image(nsImage: browser.icon)
                                        Text(browser.name)
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 200)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
withExtendedLifetime(delegate) {
    app.run()
}
