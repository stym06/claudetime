import Foundation

/// Tracks a cumulative OTLP counter with reset detection
struct CumulativeCounter {
    private var lastRawValue: Double = 0
    private var accumulatedBeforeReset: Double = 0

    var total: Double {
        return accumulatedBeforeReset + lastRawValue
    }

    mutating func update(rawValue: Double) {
        if rawValue < lastRawValue {
            // Counter reset detected (Claude Code restarted)
            accumulatedBeforeReset += lastRawValue
        }
        lastRawValue = rawValue
    }

    mutating func reset() {
        lastRawValue = 0
        accumulatedBeforeReset = 0
    }
}

/// Fixed-size circular buffer for time-series sparkline data
struct TimeSeriesBuffer {
    private var values: [Double] = []
    private let maxSize: Int = 30

    mutating func record(_ value: Double) {
        values.append(value)
        if values.count > maxSize { values.removeFirst() }
    }

    mutating func reset() { values.removeAll() }

    var samples: [Double] { values }
}

/// Per-model cost tracking
struct ModelCost {
    var name: String
    var counter: CumulativeCounter = CumulativeCounter()
}

class MetricsStore {
    var inputTokens = CumulativeCounter()
    var outputTokens = CumulativeCounter()
    var cacheReadTokens = CumulativeCounter()
    var cacheCreationTokens = CumulativeCounter()
    var costByModel: [String: CumulativeCounter] = [:]
    var sessionCount = CumulativeCounter()
    var linesAdded = CumulativeCounter()
    var linesRemoved = CumulativeCounter()
    var commitCount = CumulativeCounter()
    var prCount = CumulativeCounter()
    var activeTimeSeconds = CumulativeCounter()

    // Time-series history buffers for sparklines
    var inputTokensHistory = TimeSeriesBuffer()
    var outputTokensHistory = TimeSeriesBuffer()
    var cacheReadHistory = TimeSeriesBuffer()
    var cacheCreationHistory = TimeSeriesBuffer()
    var totalCostHistory = TimeSeriesBuffer()
    var sessionHistory = TimeSeriesBuffer()
    var activeTimeHistory = TimeSeriesBuffer()
    var linesAddedHistory = TimeSeriesBuffer()
    var linesRemovedHistory = TimeSeriesBuffer()
    var commitHistory = TimeSeriesBuffer()
    var prHistory = TimeSeriesBuffer()

    var hasReceivedData = false
    var lastUpdateTime: Date?

    var totalCost: Double {
        return costByModel.values.reduce(0) { $0 + $1.total }
    }

    func ingest(_ dataPoints: [MetricDataPoint]) {
        for dp in dataPoints {
            switch dp.name {
            case "claude_code.token.usage":
                let tokenType = dp.attributes["type"] ?? ""
                switch tokenType {
                case "input":
                    inputTokens.update(rawValue: dp.value)
                case "output":
                    outputTokens.update(rawValue: dp.value)
                case "cacheRead":
                    cacheReadTokens.update(rawValue: dp.value)
                case "cacheCreation":
                    cacheCreationTokens.update(rawValue: dp.value)
                default:
                    break
                }
            case "claude_code.cost.usage":
                let model = dp.attributes["model"] ?? "unknown"
                if costByModel[model] == nil {
                    costByModel[model] = CumulativeCounter()
                }
                costByModel[model]!.update(rawValue: dp.value)
            case "claude_code.session.count":
                sessionCount.update(rawValue: dp.value)
            case "claude_code.lines_of_code.count":
                let locType = dp.attributes["type"] ?? ""
                switch locType {
                case "added":
                    linesAdded.update(rawValue: dp.value)
                case "removed":
                    linesRemoved.update(rawValue: dp.value)
                default:
                    break
                }
            case "claude_code.commit.count":
                commitCount.update(rawValue: dp.value)
            case "claude_code.pr.count":
                prCount.update(rawValue: dp.value)
            case "claude_code.active_time.duration":
                activeTimeSeconds.update(rawValue: dp.value)
            default:
                break
            }
        }
        hasReceivedData = true
        lastUpdateTime = Date()
        recordSnapshot()
    }

    private func recordSnapshot() {
        inputTokensHistory.record(inputTokens.total)
        outputTokensHistory.record(outputTokens.total)
        cacheReadHistory.record(cacheReadTokens.total)
        cacheCreationHistory.record(cacheCreationTokens.total)
        totalCostHistory.record(totalCost)
        sessionHistory.record(sessionCount.total)
        activeTimeHistory.record(activeTimeSeconds.total)
        linesAddedHistory.record(linesAdded.total)
        linesRemovedHistory.record(linesRemoved.total)
        commitHistory.record(commitCount.total)
        prHistory.record(prCount.total)
    }

    func resetAll() {
        inputTokens.reset()
        outputTokens.reset()
        cacheReadTokens.reset()
        cacheCreationTokens.reset()
        costByModel.removeAll()
        sessionCount.reset()
        linesAdded.reset()
        linesRemoved.reset()
        commitCount.reset()
        prCount.reset()
        activeTimeSeconds.reset()
        inputTokensHistory.reset()
        outputTokensHistory.reset()
        cacheReadHistory.reset()
        cacheCreationHistory.reset()
        totalCostHistory.reset()
        sessionHistory.reset()
        activeTimeHistory.reset()
        linesAddedHistory.reset()
        linesRemovedHistory.reset()
        commitHistory.reset()
        prHistory.reset()
        hasReceivedData = false
        lastUpdateTime = nil
    }
}
