//
//  SwiftDataManager.swift
//  VideoSpeed
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataManager {
    static let shared = SwiftDataManager()

    let container: ModelContainer

    var modelContext: ModelContext {
        container.mainContext
    }

    private init() {
        do {
            container = try ModelContainer(for: VideoProject.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
