import AppKit
import SwiftUI

func createMenuBarIcon() -> NSImage {
    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size, flipped: false) { rect in
        let ctx = NSGraphicsContext.current!.cgContext
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius: CGFloat = 7.5

        // Circle outline
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(1.5)
        ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.strokePath()

        // Clock hands — minute hand pointing up, hour hand pointing to ~2 o'clock
        ctx.setLineCap(.round)
        ctx.setLineWidth(1.5)

        // Minute hand (up)
        ctx.move(to: center)
        ctx.addLine(to: CGPoint(x: center.x, y: center.y + 5.5))
        ctx.strokePath()

        // Hour hand (~2 o'clock direction)
        ctx.move(to: center)
        ctx.addLine(to: CGPoint(x: center.x + 3.2, y: center.y + 2.5))
        ctx.strokePath()

        // Small dot at center
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.addArc(center: center, radius: 1, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.fillPath()

        return true
    }
    image.isTemplate = true
    return image
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusBarItem: NSStatusItem!
    let metricsStore = MetricsStore()
    let server = OTLPServer()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusBarItem.button {
            button.image = createMenuBarIcon()
            button.imagePosition = .imageLeading
            button.title = ""
        }

        let menu = NSMenu()
        menu.delegate = self
        statusBarItem.menu = menu

        server.onMetricsReceived = { [weak self] dataPoints in
            guard let self = self else { return }
            self.metricsStore.ingest(dataPoints)
            self.updateMenuBarTitle()
        }
        server.start()
    }

    func updateMenuBarTitle() {
        guard metricsStore.hasReceivedData else { return }
        let input = formatTokenCount(metricsStore.inputTokens.total)
        let output = formatTokenCount(metricsStore.outputTokens.total)
        statusBarItem.button?.title = " ↑\(input) ↓\(output)"
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()

        if !metricsStore.hasReceivedData {
            let waitingItem = NSMenuItem(title: "Waiting for Claude Code metrics...", action: nil, keyEquivalent: "")
            waitingItem.isEnabled = false
            menu.addItem(waitingItem)

            menu.addItem(NSMenuItem.separator())

            let setupHeader = NSMenuItem(title: "Setup:", action: nil, keyEquivalent: "")
            setupHeader.isEnabled = false
            menu.addItem(setupHeader)

            let instructions = [
                "export CLAUDE_CODE_ENABLE_TELEMETRY=1",
                "export OTEL_METRICS_EXPORTER=otlp",
                "export OTEL_EXPORTER_OTLP_PROTOCOL=http/json",
                "export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318",
                "export OTEL_METRIC_EXPORT_INTERVAL=10000"
            ]
            for instruction in instructions {
                let item = NSMenuItem(title: "  \(instruction)", action: nil, keyEquivalent: "")
                item.isEnabled = false
                let font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
                item.attributedTitle = NSAttributedString(string: "  \(instruction)", attributes: [.font: font])
                menu.addItem(item)
            }

            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            return
        }

        // SwiftUI dashboard view
        let dashboardView = MetricsDashboardView(store: metricsStore)
        let hostingView = NSHostingView(rootView: dashboardView)
        hostingView.frame.size = hostingView.fittingSize

        let dashboardItem = NSMenuItem()
        dashboardItem.view = hostingView
        menu.addItem(dashboardItem)

        // Footer actions
        menu.addItem(NSMenuItem.separator())

        let resetItem = NSMenuItem(title: "Reset Stats", action: #selector(resetStats), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc func resetStats() {
        metricsStore.resetAll()
        statusBarItem.button?.title = ""
    }
}
