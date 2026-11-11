import Foundation
import IOKit.ps

/// Lee el nivel de batería del sistema y lo refresca periódicamente.
final class BatteryMonitor: ObservableObject {
    /// Porcentaje de 0 a 100, o `nil` si el equipo no tiene batería.
    @Published var level: Int?
    @Published var isCharging = false

    private var timer: Timer?

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        timer?.invalidate()
    }

    func refresh() {
        guard
            let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef]
        else {
            level = nil
            return
        }

        for source in sources {
            guard
                let info = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any],
                let current = info[kIOPSCurrentCapacityKey] as? Int,
                let max = info[kIOPSMaxCapacityKey] as? Int,
                max > 0
            else { continue }

            level = Int((Double(current) / Double(max) * 100).rounded())
            isCharging = (info[kIOPSIsChargingKey] as? Bool) ?? false
            return
        }
        level = nil
    }
}
