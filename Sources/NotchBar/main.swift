import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Sin icono en el Dock: la app vive en el notch y en la barra de menús.
app.setActivationPolicy(.accessory)
app.run()
