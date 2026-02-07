import Foundation

func formatTokenCount(_ value: Double) -> String {
    if value >= 1_000_000 {
        return String(format: "%.1fM", value / 1_000_000)
    } else if value >= 1_000 {
        return String(format: "%.1fK", value / 1_000)
    }
    return "\(Int(value))"
}

func formatFullNumber(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = ","
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
}

func formatCost(_ value: Double) -> String {
    if value < 0.01 && value > 0 {
        return String(format: "$%.4f", value)
    }
    return String(format: "$%.2f", value)
}

func sparkline(_ values: [Double]) -> String {
    guard values.count >= 2 else { return "" }
    let blocks: [Character] = ["▁","▂","▃","▄","▅","▆","▇","█"]
    let mn = values.min()!, mx = values.max()!
    let range = mx - mn
    return String(values.map { v in
        if range == 0 { return blocks[0] }
        let idx = Int(((v - mn) / range) * 7)
        return blocks[min(idx, 7)]
    })
}

func formatActiveTime(_ seconds: Double) -> String {
    let totalSeconds = Int(seconds)
    if totalSeconds < 60 {
        return "\(totalSeconds)s"
    }
    let minutes = totalSeconds / 60
    let secs = totalSeconds % 60
    if minutes < 60 {
        return "\(minutes)m \(secs)s"
    }
    let hours = minutes / 60
    let mins = minutes % 60
    return "\(hours)h \(mins)m"
}
