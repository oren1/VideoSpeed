//
//  DebugSessionLog.swift
//  VideoSpeed
//
//  Temporary debug instrumentation — remove after investigation.
//

import Foundation
import UIKit

enum DebugSessionLog {
    private static let sessionId = "45f3ba"
    private static let ingestURL = URL(string: "http://127.0.0.1:7531/ingest/08b59bce-f935-4e31-96aa-795a337948b4")!
    private static var logPath: String {
        #if targetEnvironment(simulator)
        return "/Users/orenshalev/Desktop/VideoSpeed/.cursor/debug-45f3ba.log"
        #else
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("debug-45f3ba.log").path
        #endif
    }

    static func write(
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: Any] = [:],
        runId: String = "pre-fix"
    ) {
        var payload: [String: Any] = [
            "sessionId": sessionId,
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "runId": runId,
            "device": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion
        ]

        guard JSONSerialization.isValidJSONObject(payload),
              let json = try? JSONSerialization.data(withJSONObject: payload),
              let line = String(data: json, encoding: .utf8) else { return }

        print("[DEBUG 45f3ba] \(line)")

        var request = URLRequest(url: ingestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(sessionId, forHTTPHeaderField: "X-Debug-Session-Id")
        request.httpBody = json
        URLSession.shared.dataTask(with: request).resume()

        if !FileManager.default.fileExists(atPath: logPath) {
            FileManager.default.createFile(atPath: logPath, contents: nil)
        }
        if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: logPath)) {
            defer { try? handle.close() }
            try? handle.seekToEnd()
            if let bytes = (line + "\n").data(using: .utf8) {
                try? handle.write(contentsOf: bytes)
            }
        }
    }

    /// Approximate resident memory (bytes) for export OOM diagnostics.
    static func residentMemoryBytes() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
}
