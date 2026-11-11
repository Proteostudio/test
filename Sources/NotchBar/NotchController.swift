import AppKit
import SwiftUI

/// Panel sin bordes que no roba el foco a la app activa.
final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Permite que el primer clic actúe aunque la ventana no sea la activa.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

/// Coloca el panel sobre el notch y lo despliega/pliega según la posición del ratón.
final class NotchController {
    let model = NotchModel()

    private let panel: NotchPanel
    private var monitors: [Any] = []
    private var screenObserver: NSObjectProtocol?

    private let animationDuration: TimeInterval = 0.45

    init() {
        panel = NotchPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        // Por encima de la barra de menús, para poder tapar el notch.
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]

        let hosting = FirstMouseHostingView(rootView: NotchView(model: model))
        hosting.sizingOptions = []
        panel.contentView = hosting

        layout()
        panel.orderFrontRegardless()

        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged]
        if let global = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] _ in
            self?.mouseMoved()
        }) {
            monitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] event in
            self?.mouseMoved()
            return event
        }) {
            monitors.append(local)
        }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.layout()
        }
    }

    deinit {
        monitors.forEach(NSEvent.removeMonitor)
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    // MARK: - Geometría

    /// Pantalla con notch si existe; si no, la principal.
    private var screen: NSScreen? {
        NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func notchSize(on screen: NSScreen) -> CGSize {
        let top = screen.safeAreaInsets.top
        if top > 0, let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            return CGSize(width: screen.frame.width - left.width - right.width, height: top)
        }
        // Pantalla sin notch: píldora simulada con la altura de la barra de menús.
        let menuBar = screen.frame.maxY - screen.visibleFrame.maxY
        return CGSize(width: 190, height: max(menuBar, 24))
    }

    /// Rectángulo centrado y pegado al borde superior de la pantalla.
    private func topRect(_ size: CGSize, on screen: NSScreen) -> NSRect {
        NSRect(
            x: screen.frame.midX - size.width / 2,
            y: screen.frame.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }

    private func layout() {
        guard let screen else { return }
        model.notchSize = notchSize(on: screen)
        let size = model.expanded ? model.expandedSize : model.notchSize
        panel.setFrame(topRect(size, on: screen), display: true)
    }

    // MARK: - Desplegar / plegar

    private func mouseMoved() {
        guard let screen else { return }
        let mouse = NSEvent.mouseLocation

        if model.expanded {
            let keepOpen = topRect(model.expandedSize, on: screen).insetBy(dx: -12, dy: -12)
            if !keepOpen.contains(mouse) { collapse() }
        } else {
            // Se amplía 1 pt hacia arriba porque el cursor puede quedar justo en el borde.
            let trigger = topRect(model.notchSize, on: screen).insetBy(dx: 0, dy: -1)
            if trigger.contains(mouse) { expand() }
        }
    }

    private func expand() {
        guard let screen, !model.expanded else { return }
        // Primero crece la ventana; el contenido se anima dentro.
        panel.setFrame(topRect(model.expandedSize, on: screen), display: true)
        model.expanded = true
    }

    private func collapse() {
        guard model.expanded else { return }
        model.expanded = false
        // La ventana se encoge cuando termina la animación, si no se ha vuelto a abrir.
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [weak self] in
            guard let self, !self.model.expanded, let screen = self.screen else { return }
            self.panel.setFrame(self.topRect(self.model.notchSize, on: screen), display: true)
        }
    }
}
