import AppKit
import Combine

final class NotchModel: ObservableObject {
    /// `true` mientras el panel está desplegado bajo el notch.
    @Published var expanded = false
    /// Tamaño del notch físico (o de la píldora simulada en pantallas sin notch).
    @Published var notchSize = CGSize(width: 190, height: 32)
    /// Archivos soltados en la bandeja.
    @Published var shelf: [URL] = []

    var expandedSize: CGSize {
        CGSize(width: max(560, notchSize.width + 240), height: notchSize.height + 124)
    }

    func addFiles(from providers: [NSItemProvider]) {
        for provider in providers where provider.canLoadObject(ofClass: URL.self) {
            _ = provider.loadObject(ofClass: URL.self) { [weak self] url, _ in
                guard let url, url.isFileURL else { return }
                DispatchQueue.main.async {
                    guard let self, !self.shelf.contains(url) else { return }
                    self.shelf.append(url)
                }
            }
        }
    }

    func remove(_ url: URL) {
        shelf.removeAll { $0 == url }
    }
}
