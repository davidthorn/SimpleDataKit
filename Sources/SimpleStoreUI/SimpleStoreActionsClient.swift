//
//  SimpleStoreActionsClient.swift
//  SimpleStoreUI
//
//  Created by David Thorn on 21.02.2026.
//

import Foundation

#if canImport(SwiftUI) && canImport(Combine)
import Combine
import SimpleStore
import SwiftUI

@MainActor
public final class SimpleStoreActionsClient<Model: Codable & Identifiable & Sendable & Hashable>: ObservableObject where Model.ID: Hashable & Sendable {
    @Published public private(set) var items: [Model]
    @Published public private(set) var lastError: Error?

    private let directory: FileManager.SearchPathDirectory
    private let storeName: String?
    private var observationTask: Task<Void, Never>?

    public init(
        type: Model.Type,
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
        storeName: String? = nil
    ) {
        _ = type
        self.directory = directory
        self.storeName = storeName
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
                let store = try await resolveStore()
                let loaded = try await store.all()
                if Task.isCancelled {
                    return
                }
                items = loaded

                let updates = await store.stream
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

    public func all() async throws -> [Model] {
        let store = try await resolveStore()
        return try await store.all()
    }

    public func read(id: Model.ID) async throws -> Model {
        let store = try await resolveStore()
        return try await store.read(id: id)
    }

    public func exists(id: Model.ID) async throws -> Bool {
        let store = try await resolveStore()
        return try await store.exists(id: id)
    }

    public func insert(_ model: Model) async throws {
        let store = try await resolveStore()
        try await store.insert(model)
    }

    public func upsert(_ model: Model) async throws {
        let store = try await resolveStore()
        try await store.upsert(model)
    }

    public func update(_ model: Model) async throws {
        let store = try await resolveStore()
        try await store.update(model)
    }

    public func delete(id: Model.ID) async throws {
        let store = try await resolveStore()
        try await store.delete(id: id)
    }

    public func deleteAll() async throws {
        let store = try await resolveStore()
        try await store.deleteAll()
    }

    @available(*, deprecated, renamed: "delete(id:)")
    public func remove(id: Model.ID) async throws {
        try await delete(id: id)
    }

    @available(*, deprecated, renamed: "deleteAll()")
    public func removeAll() async throws {
        try await deleteAll()
    }

    public func query(where predicate: @Sendable (Model) -> Bool) async throws -> [Model] {
        let store = try await resolveStore()
        return try await store.filter(where: predicate)
    }

    public func loadFirst(where predicate: @Sendable (Model) -> Bool) async throws -> Model? {
        let store = try await resolveStore()
        return try await store.first(where: predicate)
    }

    public func contains(where predicate: @Sendable (Model) -> Bool) async throws -> Bool {
        let store = try await resolveStore()
        return try await store.contains(where: predicate)
    }

    public func count() async throws -> Int {
        let store = try await resolveStore()
        return try await store.count()
    }

    public func count(where predicate: @Sendable (Model) -> Bool) async throws -> Int {
        let store = try await resolveStore()
        return try await store.count(where: predicate)
    }

    public func stream() async throws -> AsyncStream<[Model]> {
        let store = try await resolveStore()
        return await store.stream
    }

    public func stream(
        bufferingPolicy: AsyncStream<[Model]>.Continuation.BufferingPolicy
    ) async throws -> AsyncStream<[Model]> {
        let store = try await resolveStore()
        return await store.makeStream(bufferingPolicy: bufferingPolicy)
    }

    private func resolveStore() async throws -> AnySimpleStore<Model> {
        try await resolveGlobalStore(for: Model.self, directory: directory, name: storeName)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
public extension SimpleStoreActionsClient {
    func insertAction<Label: View>(
        makeModel: @escaping @Sendable () -> Model,
        onCompletion: @escaping @MainActor @Sendable (Error?) -> Void = { _ in },
        @ViewBuilder label: @escaping () -> Label
    ) -> some View {
        SimpleStoreInsertButton(
            Model.self,
            directory: directory,
            storeName: storeName,
            makeModel: makeModel,
            onCompletion: onCompletion,
            label: label
        )
    }
    
    func deleteAction<Label: View>(
        id: Model.ID,
        onCompletion: @escaping @MainActor @Sendable (Error?) -> Void = { _ in },
        @ViewBuilder label: @escaping () -> Label
    ) -> some View {
        SimpleStoreDeleteButton(
            Model.self,
            id: id,
            directory: directory,
            storeName: storeName,
            onCompletion: onCompletion,
            label: label
        )
    }
}
#endif
