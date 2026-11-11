import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: NotchController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = NotchController()
        setUpStatusItem()
    }

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "rectangle.topthird.inset.filled",
            accessibilityDescription: "NotchBar"
        )

        let menu = NSMenu()
        let clear = NSMenuItem(title: "Vaciar bandeja", action: #selector(clearShelf), keyEquivalent: "")
        clear.target = self
        menu.addItem(clear)
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(title: "Salir de NotchBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        )
        item.menu = menu
        statusItem = item
    }

    @objc private func clearShelf() {
        controller?.model.shelf.removeAll()
    }
}
