import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private let urlStore = URLStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView(urlStore: urlStore)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 200),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "URL Catcher"
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        self.window = window

        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:replyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
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
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.url)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .lineLimit(2)
                            Text(entry.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
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
                                .frame(width: 60)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 150)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
