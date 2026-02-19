//
//  SimpleStoreItemsLoader.swift
//  SimpleStore
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation

#if canImport(SwiftUI) && canImport(Combine)
import Combine
import SimpleStore

@MainActor
public final class SimpleStoreItemsLoader<Model: Codable & Identifiable & Sendable & Hashable>: ObservableObject where Model.ID: Hashable & Sendable {
    @Published public private(set) var items: [Model]
    @Published public private(set) var lastError: Error?

    private let directory: FileManager.SearchPathDirectory
    private var observationTask: Task<Void, Never>?

    public init(
        type: Model.Type,
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
    ) {
        _ = type
        self.directory = directory
        self.items = []
        self.lastError = nil
        self.observationTask = nil
    }

    deinit {
        observationTask?.cancel()
    }

    public func startIfNeeded() {
        guard observationTask == nil else {
            return
        }

        observationTask = Task {
            do {
                let loaded = try await loadAll(Model.self, directory: directory)
                if Task.isCancelled {
                    return
                }
                items = loaded

                let updates = try await stream(Model.self, directory: directory)
                for await snapshot in updates {
                    if Task.isCancelled {
                        return
                    }
                    items = snapshot
                }
            } catch {
                if Task.isCancelled {
                    return
                }
                lastError = error
            }
        }
    }

    public func refresh() {
        observationTask?.cancel()
        observationTask = nil
        startIfNeeded()
    }
}
#endif
