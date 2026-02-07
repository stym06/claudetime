import Foundation
import Network

struct MetricDataPoint {
    let name: String
    let value: Double
    let attributes: [String: String]
}

func parseOTLPMetrics(from data: Data) -> [MetricDataPoint] {
    var results: [MetricDataPoint] = []

    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let resourceMetrics = json["resourceMetrics"] as? [[String: Any]] else {
        return results
    }

    for rm in resourceMetrics {
        guard let scopeMetrics = rm["scopeMetrics"] as? [[String: Any]] else { continue }
        for sm in scopeMetrics {
            guard let metrics = sm["metrics"] as? [[String: Any]] else { continue }
            for metric in metrics {
                guard let name = metric["name"] as? String else { continue }

                // Handle sum metrics (cumulative counters)
                if let sum = metric["sum"] as? [String: Any],
                   let dataPoints = sum["dataPoints"] as? [[String: Any]] {
                    for dp in dataPoints {
                        let value = extractValue(from: dp)
                        let attrs = extractAttributes(from: dp)
                        results.append(MetricDataPoint(name: name, value: value, attributes: attrs))
                    }
                }

                // Handle gauge metrics
                if let gauge = metric["gauge"] as? [String: Any],
                   let dataPoints = gauge["dataPoints"] as? [[String: Any]] {
                    for dp in dataPoints {
                        let value = extractValue(from: dp)
                        let attrs = extractAttributes(from: dp)
                        results.append(MetricDataPoint(name: name, value: value, attributes: attrs))
                    }
                }
            }
        }
    }

    return results
}

private func extractValue(from dataPoint: [String: Any]) -> Double {
    // asInt can be a string or number
    if let asIntStr = dataPoint["asInt"] as? String, let v = Double(asIntStr) {
        return v
    }
    if let asInt = dataPoint["asInt"] as? NSNumber {
        return asInt.doubleValue
    }
    if let asDouble = dataPoint["asDouble"] as? Double {
        return asDouble
    }
    if let asDouble = dataPoint["asDouble"] as? NSNumber {
        return asDouble.doubleValue
    }
    return 0
}

private func extractAttributes(from dataPoint: [String: Any]) -> [String: String] {
    var attrs: [String: String] = [:]
    guard let attributes = dataPoint["attributes"] as? [[String: Any]] else {
        return attrs
    }
    for attr in attributes {
        guard let key = attr["key"] as? String else { continue }
        if let valueObj = attr["value"] as? [String: Any],
           let stringValue = valueObj["stringValue"] as? String {
            attrs[key] = stringValue
        }
    }
    return attrs
}

class OTLPServer {
    private var listener: NWListener?
    var onMetricsReceived: (([MetricDataPoint]) -> Void)?

    func start() {
        let params = NWParameters.tcp
        // Bind to localhost only — no firewall prompt
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: .ipv4(.loopback), port: 4318)

        do {
            listener = try NWListener(using: params)
        } catch {
            print("Failed to create listener: \(error)")
            return
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }

        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("OTLP server listening on 127.0.0.1:4318")
            case .failed(let error):
                print("OTLP server failed: \(error)")
            default:
                break
            }
        }

        listener?.start(queue: .main)
    }

    func stop() {
        listener?.cancel()
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .main)
        receiveHTTPRequest(connection: connection, buffer: Data())
    }

    private func receiveHTTPRequest(connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self = self else { return }

            if let error = error {
                print("Connection error: \(error)")
                connection.cancel()
                return
            }

            var accumulated = buffer
            if let content = content {
                accumulated.append(content)
            }

            // Try to parse a complete HTTP request
            if let request = self.tryParseHTTPRequest(data: accumulated) {
                self.handleHTTPRequest(request: request, connection: connection)
            } else if isComplete {
                // Connection closed before complete request
                connection.cancel()
            } else {
                // Need more data
                self.receiveHTTPRequest(connection: connection, buffer: accumulated)
            }
        }
    }

    private struct HTTPRequest {
        let method: String
        let path: String
        let body: Data
    }

    private func tryParseHTTPRequest(data: Data) -> HTTPRequest? {
        guard let str = String(data: data, encoding: .utf8) else { return nil }

        // Find end of headers
        guard let headerEndRange = str.range(of: "\r\n\r\n") else { return nil }

        let headerPart = String(str[str.startIndex..<headerEndRange.lowerBound])
        let headerEndByteOffset = data.count - Data(str[headerEndRange.upperBound...].utf8).count

        // Parse request line
        let lines = headerPart.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }
        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else { return nil }
        let method = parts[0]
        let path = parts[1]

        // Find Content-Length
        var contentLength = 0
        for line in lines.dropFirst() {
            let lower = line.lowercased()
            if lower.hasPrefix("content-length:") {
                let valStr = line.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)
                contentLength = Int(valStr) ?? 0
                break
            }
        }

        // Check if we have the full body
        let bodyStart = headerEndByteOffset
        let availableBody = data.count - bodyStart
        if availableBody < contentLength {
            return nil // Need more data
        }

        let body = data.subdata(in: bodyStart..<(bodyStart + contentLength))
        return HTTPRequest(method: method, path: path, body: body)
    }

    private func handleHTTPRequest(request: HTTPRequest, connection: NWConnection) {
        if request.method == "POST" && request.path == "/v1/metrics" {
            let dataPoints = parseOTLPMetrics(from: request.body)
            if !dataPoints.isEmpty {
                onMetricsReceived?(dataPoints)
            }
        }
        // Accept /v1/logs, /v1/traces, etc. with 200 OK (discard body)

        let response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}"
        let responseData = Data(response.utf8)
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
