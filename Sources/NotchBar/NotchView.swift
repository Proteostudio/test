import SwiftUI
import UniformTypeIdentifiers

/// Silueta del notch: recta arriba, esquinas redondeadas abajo.
struct NotchShape: Shape {
    var radius: CGFloat

    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let r = min(radius, rect.width / 2, rect.height)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
            radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
            radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

struct NotchView: View {
    @ObservedObject var model: NotchModel

    var body: some View {
        let size = model.expanded ? model.expandedSize : model.notchSize

        ZStack(alignment: .top) {
            NotchShape(radius: model.expanded ? 22 : 8)
                .fill(Color.black)

            if model.expanded {
                HStack(alignment: .center, spacing: 16) {
                    ClockView()
                    ShelfView(model: model)
                    BatteryView()
                }
                .padding(.top, model.notchSize.height + 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
                .transition(.opacity)
            }
        }
        .frame(width: size.width, height: size.height)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: model.expanded)
        .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
            model.addFiles(from: providers)
            return true
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Reloj

struct ClockView: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 2) {
                Text(context.date, format: .dateTime.hour().minute())
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text(context.date, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .frame(width: 140, alignment: .leading)
    }
}

// MARK: - Bandeja de archivos

struct ShelfView: View {
    @ObservedObject var model: NotchModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    Color.white.opacity(0.25),
                    style: StrokeStyle(lineWidth: 1, dash: model.shelf.isEmpty ? [5, 4] : [])
                )

            if model.shelf.isEmpty {
                Label("Suelta archivos aquí", systemImage: "tray.and.arrow.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(model.shelf, id: \.self) { url in
                            ShelfItemView(url: url) { model.remove(url) }
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ShelfItemView: View {
    let url: URL
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .frame(width: 40, height: 40)
            Text(url.lastPathComponent)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(width: 68)
        .contentShape(Rectangle())
        .onTapGesture { NSWorkspace.shared.open(url) }
        .onDrag { NSItemProvider(object: url as NSURL) }
        .contextMenu {
            Button("Abrir") { NSWorkspace.shared.open(url) }
            Button("Mostrar en Finder") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
            Divider()
            Button("Quitar de la bandeja", action: onRemove)
        }
        .help(url.lastPathComponent)
    }
}

// MARK: - Batería

struct BatteryView: View {
    @StateObject private var battery = BatteryMonitor()

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let level = battery.level {
                Image(systemName: symbol(for: level))
                    .font(.system(size: 22))
                    .foregroundStyle(level <= 20 && !battery.isCharging ? Color.red : Color.white)
                Text("\(level) %")
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                Image(systemName: "powerplug")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                Text("Corriente")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(width: 80, alignment: .trailing)
    }

    private func symbol(for level: Int) -> String {
        if battery.isCharging { return "battery.100.bolt" }
        switch level {
        case 88...: return "battery.100"
        case 63...: return "battery.75"
        case 38...: return "battery.50"
        case 13...: return "battery.25"
        default: return "battery.0"
        }
    }
}
