import AppKit
import SwiftUI
import DSFSparkline

struct SparklineView: View {
    let values: [Double]
    let color: NSColor

    var body: some View {
        if values.count >= 2 {
            let ds = DSFSparkline.DataSource(values: values.map { CGFloat($0) })
            DSFSparklineLineGraphView.SwiftUI(
                dataSource: ds,
                graphColor: color,
                lineWidth: 1.5,
                interpolated: true,
                lineShading: true,
                shadowed: false,
                showZeroLine: false
            )
            .frame(width: 60, height: 20)
        }
    }
}

struct MetricsDashboardView: View {
    let store: MetricsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 6) {
                Text("⚡")
                    .font(.system(size: 16))
                Text("ClaudeTime")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .indigo, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
                // Live dot
                Circle()
                    .fill(.green)
                    .frame(width: 7, height: 7)
                Text("Live")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
            Text(updatedTimeText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            // Cost section
            sectionHeader("Cost", icon: "●", color: .green)
            metricRow("Total", formatCost(store.totalCost),
                      valueColor: .green,
                      sparkValues: store.totalCostHistory.samples, sparkColor: .systemGreen)

            let sortedModels = store.costByModel.sorted { $0.value.total > $1.value.total }
            if sortedModels.count > 1 {
                ForEach(sortedModels, id: \.key) { model, counter in
                    metricRow(model, formatCost(counter.total), valueColor: .green)
                }
            }

            Divider()

            // Tokens section
            sectionHeader("Tokens", icon: "◆", color: .cyan)
            metricRow("Input", formatFullNumber(store.inputTokens.total),
                      sparkValues: store.inputTokensHistory.samples, sparkColor: .systemCyan)
            metricRow("Output", formatFullNumber(store.outputTokens.total),
                      sparkValues: store.outputTokensHistory.samples, sparkColor: .systemBlue)
            metricRow("Cache Read", formatFullNumber(store.cacheReadTokens.total),
                      sparkValues: store.cacheReadHistory.samples, sparkColor: .systemTeal)
            metricRow("Cache Create", formatFullNumber(store.cacheCreationTokens.total),
                      sparkValues: store.cacheCreationHistory.samples, sparkColor: .systemMint)

            Divider()

            // Activity section
            sectionHeader("Activity", icon: "▲", color: .orange)
            metricRow("Sessions", formatFullNumber(store.sessionCount.total),
                      sparkValues: store.sessionHistory.samples, sparkColor: .systemOrange)
            metricRow("Active Time", formatActiveTime(store.activeTimeSeconds.total),
                      sparkValues: store.activeTimeHistory.samples, sparkColor: .systemYellow)
            metricRow("Lines Added", formatFullNumber(store.linesAdded.total),
                      valueColor: .green,
                      sparkValues: store.linesAddedHistory.samples, sparkColor: .systemGreen)
            metricRow("Lines Removed", formatFullNumber(store.linesRemoved.total),
                      valueColor: .red,
                      sparkValues: store.linesRemovedHistory.samples, sparkColor: .systemRed)
            metricRow("Commits", formatFullNumber(store.commitCount.total),
                      sparkValues: store.commitHistory.samples, sparkColor: .systemPurple)
            metricRow("PRs", formatFullNumber(store.prCount.total),
                      sparkValues: store.prHistory.samples, sparkColor: .systemIndigo)
        }
        .padding()
        .frame(width: 320)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .controlBackgroundColor),
                    Color(nsColor: .controlBackgroundColor).opacity(0.85),
                    Color.indigo.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var updatedTimeText: String {
        guard let lastUpdate = store.lastUpdateTime else {
            return "No data yet"
        }
        let elapsed = Date().timeIntervalSince(lastUpdate)
        if elapsed < 5 {
            return "Updated just now"
        } else if elapsed < 60 {
            return "Updated \(Int(elapsed))s ago"
        } else if elapsed < 3600 {
            return "Updated \(Int(elapsed / 60))m ago"
        } else {
            return "Updated \(Int(elapsed / 3600))h ago"
        }
    }

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(icon)
                .foregroundStyle(color)
                .font(.system(size: 10))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private func metricRow(
        _ label: String,
        _ value: String,
        valueColor: Color? = nil,
        sparkValues: [Double] = [],
        sparkColor: NSColor = .secondaryLabelColor
    ) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .frame(width: 130, alignment: .leading)
            Spacer()
            Text(value)
                .foregroundStyle(valueColor ?? .primary)
            SparklineView(values: sparkValues, color: sparkColor)
        }
        .font(.system(size: 13, design: .monospaced))
    }
}
