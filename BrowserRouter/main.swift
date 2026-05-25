import Cocoa
import SwiftUI

enum Theme {
    static let bgDark = Color(red: 0.08, green: 0.18, blue: 0.28)
    static let bgMid = Color(red: 0.10, green: 0.22, blue: 0.33)
    static let accent = Color(red: 0.3, green: 0.75, blue: 0.95)
    static let highlight = Color(red: 0.3, green: 0.75, blue: 0.95).opacity(0.12)
    static let textPrimary = Color(red: 0.85, green: 0.92, blue: 0.97)
    static let textSecondary = Color(red: 0.5, green: 0.65, blue: 0.75)
    static let border = Color(red: 0.2, green: 0.4, blue: 0.55)
}

class Settings: ObservableObject {
    static let shared = Settings()

    @Published var iconOnly: Bool {
        didSet { UserDefaults.standard.set(iconOnly, forKey: "iconOnly") }
    }
    @Published var clearOnClose: Bool {
        didSet { UserDefaults.standard.set(clearOnClose, forKey: "clearOnClose") }
    }
    @Published var autoCloseOnAction: Bool {
        didSet { UserDefaults.standard.set(autoCloseOnAction, forKey: "autoCloseOnAction") }
    }
    @Published var uiScale: Double {
        didSet { UserDefaults.standard.set(uiScale, forKey: "uiScale") }
    }
    @Published var windowWidth: Double {
        didSet { UserDefaults.standard.set(windowWidth, forKey: "windowWidth") }
    }
    @Published var windowHeight: Double {
        didSet { UserDefaults.standard.set(windowHeight, forKey: "windowHeight") }
    }
    @Published var hiddenBrowserIds: Set<String> {
        didSet { UserDefaults.standard.set(Array(hiddenBrowserIds), forKey: "hiddenBrowserIds") }
    }

    var scaledFont: Font { .system(size: 13 * uiScale, design: .monospaced) }
    var scaledButtonFont: Font { .system(size: 13 * pow(uiScale, 1.15)) }
    var scaledCaption: Font { .system(size: 10 * uiScale) }
    var scaledIconSize: CGFloat { 16 * pow(uiScale, 1.15) }
    var scaledPadH: CGFloat { 14 * uiScale }
    var scaledPadV: CGFloat { 10 * uiScale }
    var scaledButtonWidth: CGFloat { 54 * uiScale }
    var scaledIconButtonSize: CGFloat { 20 * pow(uiScale, 1.15) }

    private init() {
        self.iconOnly = UserDefaults.standard.bool(forKey: "iconOnly")
        self.clearOnClose = UserDefaults.standard.bool(forKey: "clearOnClose")
        self.autoCloseOnAction = UserDefaults.standard.bool(forKey: "autoCloseOnAction")
        let storedScale = UserDefaults.standard.double(forKey: "uiScale")
        self.uiScale = storedScale > 0 ? storedScale : 1.0
        let storedW = UserDefaults.standard.double(forKey: "windowWidth")
        self.windowWidth = storedW > 0 ? storedW : 600
        let storedH = UserDefaults.standard.double(forKey: "windowHeight")
        self.windowHeight = storedH > 0 ? storedH : 300
        let storedHidden = UserDefaults.standard.stringArray(forKey: "hiddenBrowserIds") ?? []
        self.hiddenBrowserIds = Set(storedHidden)
    }
}

func debugLog(_ msg: String) {
    let line = "\(msg)\n"
    if !FileManager.default.fileExists(atPath: "/tmp/browser-router-debug.log") {
        try? "".write(toFile: "/tmp/browser-router-debug.log", atomically: false, encoding: .utf8)
    }
    if let fh = FileHandle(forWritingAtPath: "/tmp/browser-router-debug.log") {
        fh.seekToEndOfFile()
        fh.write(line.data(using: .utf8)!)
        fh.closeFile()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var settingsWindow: NSWindow?
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

        let s = Settings.shared
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: s.windowWidth, height: s.windowHeight),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.title = "Browser Router v\(appVersion).0.0"
        window.backgroundColor = NSColor(red: 0.08, green: 0.18, blue: 0.28, alpha: 1.0)
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = NSHostingView(rootView: contentView)
        window.contentMinSize = NSSize(width: 300, height: 150)
        window.setContentSize(NSSize(width: s.windowWidth, height: s.windowHeight))
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.delegate = self
        self.window = window
        // NSHostingView shrinks the window to fit content on first layout pass,
        // so re-apply the desired size in the next runloop tick.
        let targetSize = NSSize(width: s.windowWidth, height: s.windowHeight)
        DispatchQueue.main.async {
            window.setContentSize(targetSize)
            window.center()
        }
    }

    private func setupMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Browser Router", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Browser Router", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
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

    @objc func openSettings() {
        if let existing = settingsWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.title = "Browser Router Settings"
        window.level = .floating
        window.center()
        window.contentView = NSHostingView(rootView: SettingsView())
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        self.settingsWindow = window
    }

    func closeMainWindow() {
        window?.performClose(nil)
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

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow,
              closingWindow === window else { return }
        if Settings.shared.clearOnClose {
            urlStore.clear()
        }
    }
}

struct BrowserInfo: Identifiable {
    let id: String // bundle identifier
    let name: String
    let icon: NSImage

    static func allBrowsers() -> [BrowserInfo] {
        let myBundleId = (Bundle.main.bundleIdentifier ?? "").lowercased()
        let httpsURL = URL(string: "https://example.com")!
        let appURLs = NSWorkspace.shared.urlsForApplications(toOpen: httpsURL)

        var seen = Set<String>()
        return appURLs.compactMap { appURL -> BrowserInfo? in
            guard let bundle = Bundle(url: appURL),
                  let bundleId = bundle.bundleIdentifier?.lowercased() else { return nil }
            guard bundleId != myBundleId else { return nil }
            guard seen.insert(bundleId).inserted else { return nil }
            var name = FileManager.default.displayName(atPath: appURL.path)
            if name.hasSuffix(".app") { name = String(name.dropLast(4)) }
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            return BrowserInfo(id: bundleId, name: name, icon: icon)
        }
    }

    static func visibleBrowsers() -> [BrowserInfo] {
        let hidden = Settings.shared.hiddenBrowserIds
        return allBrowsers().filter { !hidden.contains($0.id) }
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
    @Published var highlightedId: UUID?

    struct URLEntry: Identifiable {
        let id = UUID()
        let url: String
        let timestamp: Date
    }

    func addURL(_ url: String) {
        let entry = URLEntry(url: url, timestamp: Date())
        DispatchQueue.main.async {
            self.urls.insert(entry, at: 0)
            self.highlightedId = entry.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if self.highlightedId == entry.id {
                    self.highlightedId = nil
                }
            }
        }
    }

    func clear() {
        DispatchQueue.main.async {
            self.urls.removeAll()
            self.highlightedId = nil
        }
    }
}

struct SettingsView: View {
    @ObservedObject private var settings = Settings.shared
    private let allBrowsers = BrowserInfo.allBrowsers()

    private var visibleBrowsers: [BrowserInfo] {
        allBrowsers.filter { !settings.hiddenBrowserIds.contains($0.id) }
    }
    private var hiddenBrowsers: [BrowserInfo] {
        allBrowsers.filter { settings.hiddenBrowserIds.contains($0.id) }
    }

    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Icon-only browser buttons", isOn: $settings.iconOnly)
                Toggle("Clear history on window close", isOn: $settings.clearOnClose)
                Toggle("Auto-close after action", isOn: $settings.autoCloseOnAction)
            }
            Section("Appearance") {
                HStack {
                    Text("UI scale")
                    Slider(value: $settings.uiScale, in: 0.7...4.0, step: 0.1)
                    Text("\(Int(settings.uiScale * 100))%")
                        .frame(width: 48, alignment: .trailing)
                        .monospacedDigit()
                }
                HStack {
                    Text("Window width")
                    Slider(value: $settings.windowWidth, in: 300...1200, step: 50)
                    Text("\(Int(settings.windowWidth))")
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }
                HStack {
                    Text("Window height")
                    Slider(value: $settings.windowHeight, in: 150...800, step: 50)
                    Text("\(Int(settings.windowHeight))")
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }
            }
            Section("Hidden Browsers") {
                if hiddenBrowsers.isEmpty {
                    Text("No hidden browsers")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(hiddenBrowsers) { browser in
                        HStack {
                            Image(nsImage: browser.icon)
                                .frame(width: 16, height: 16)
                            Text(browser.name)
                            Spacer()
                            Button("Show") {
                                settings.hiddenBrowserIds.remove(browser.id)
                            }
                        }
                    }
                }
                Menu {
                    ForEach(visibleBrowsers) { browser in
                        Button(browser.name) {
                            settings.hiddenBrowserIds.insert(browser.id)
                        }
                    }
                } label: {
                    Label("Hide a browser...", systemImage: "minus.circle")
                }
            }
        }
        .formStyle(.grouped)
        .padding(12)
        .frame(minWidth: 400, minHeight: 420)
    }
}

struct ContentView: View {
    @ObservedObject var urlStore: URLStore
    @ObservedObject private var settings = Settings.shared
    @State private var copiedId: UUID?
    private let browsers = BrowserInfo.visibleBrowsers()

    private func performAction(_ action: () -> Void) {
        action()
        if settings.autoCloseOnAction {
            DispatchQueue.main.async {
                NSApp.keyWindow?.performClose(nil)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if urlStore.urls.isEmpty {
                Spacer()
                Text("Waiting for URLs...")
                    .font(.title2)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(urlStore.urls) { entry in
                                let isHighlighted = urlStore.highlightedId == entry.id
                                VStack(alignment: .leading, spacing: 6 * settings.uiScale) {
                                    Text(entry.url)
                                        .font(settings.scaledFont)
                                        .foregroundColor(Theme.textPrimary)
                                        .textSelection(.enabled)
                                        .lineLimit(2)
                                    Text(entry.timestamp, style: .time)
                                        .font(settings.scaledCaption)
                                        .foregroundColor(Theme.textSecondary)
                                    FlowLayout(spacing: 6 * settings.uiScale) {
                                        Button(action: {
                                            performAction {
                                                NSPasteboard.general.clearContents()
                                                NSPasteboard.general.setString(entry.url, forType: .string)
                                                copiedId = entry.id
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                    if copiedId == entry.id {
                                                        copiedId = nil
                                                    }
                                                }
                                            }
                                        }) {
                                            Text(copiedId == entry.id ? "Copied!" : "Copy")
                                                .font(settings.scaledButtonFont)
                                                .frame(width: settings.scaledButtonWidth)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(Theme.accent)

                                        ForEach(browsers) { browser in
                                            Button(action: {
                                                performAction {
                                                    browser.open(url: entry.url)
                                                }
                                            }) {
                                                if settings.iconOnly {
                                                    Image(nsImage: browser.icon)
                                                        .resizable()
                                                        .frame(width: settings.scaledIconButtonSize, height: settings.scaledIconButtonSize)
                                                } else {
                                                    HStack(spacing: 3) {
                                                        Image(nsImage: browser.icon)
                                                            .resizable()
                                                            .frame(width: settings.scaledIconSize, height: settings.scaledIconSize)
                                                        Text(browser.name)
                                                            .font(settings.scaledButtonFont)
                                                    }
                                                }
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(Theme.accent)
                                            .help(browser.name)
                                        }
                                    }
                                }
                                .padding(.horizontal, settings.scaledPadH)
                                .padding(.vertical, settings.scaledPadV)
                                .background(isHighlighted ? Theme.highlight : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(isHighlighted ? Theme.accent.opacity(0.5) : Color.clear, lineWidth: 1),
                                    alignment: .center
                                )
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(Theme.border.opacity(0.4)),
                                    alignment: .bottom
                                )
                                .id(entry.id)
                            }
                        }
                    }
                    .onChange(of: urlStore.highlightedId) {
                        if let id = urlStore.highlightedId {
                            withAnimation {
                                proxy.scrollTo(id, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .background(Theme.bgDark)
        .onChange(of: settings.windowWidth) { resizeWindow() }
        .onChange(of: settings.windowHeight) { resizeWindow() }
    }

    private func resizeWindow() {
        guard let window = NSApp.windows.first(where: { $0.title.hasPrefix("Browser Router v") }) else { return }
        var frame = window.frame
        let newSize = NSSize(width: settings.windowWidth, height: settings.windowHeight)
        frame.origin.y += frame.size.height - newSize.height
        frame.size = newSize
        window.setFrame(frame, display: true, animate: true)
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (i, row) in rows.enumerated() {
            let rowHeight = row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight
            if i > 0 { height += spacing }
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for (i, row) in rows.enumerated() {
            if i > 0 { y += spacing }
            var x = bounds.minX
            let rowHeight = row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            for idx in row {
                let size = subviews[idx].sizeThatFits(.unspecified)
                subviews[idx].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[Int]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[Int]] = [[]]
        var currentWidth: CGFloat = 0
        for (i, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if !rows[rows.count - 1].isEmpty && currentWidth + size.width > maxWidth {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(i)
            currentWidth += size.width + spacing
        }
        return rows
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
withExtendedLifetime(delegate) {
    app.run()
}
