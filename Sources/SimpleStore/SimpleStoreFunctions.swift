//
//  SimpleStoreFunctions.swift
//  SimpleStore
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation

private actor GlobalStoreRegistry {
    static let shared = GlobalStoreRegistry()
    
    private var stores: [String: AnyObject]
    
    init() {
        self.stores = [:]
    }
    
    func store<Model: Codable & Identifiable & Sendable & Hashable>(
        for type: Model.Type,
        directory: FileManager.SearchPathDirectory
    ) throws -> SimpleStore<Model> where Model.ID: Hashable & Sendable {
        let key = "\(String(reflecting: type))|\(directory.rawValue)"
        if let existing = stores[key] as? SimpleStore<Model> {
            return existing
        }
        let created = try makeSimpleStore(for: type, directory: directory)
        stores[key] = created
        return created
    }
}

private func resolveGlobalStore<Model: Codable & Identifiable & Sendable & Hashable>(
    for type: Model.Type,
    directory: FileManager.SearchPathDirectory
) async throws -> SimpleStore<Model> where Model.ID: Hashable & Sendable {
    try await GlobalStoreRegistry.shared.store(for: type, directory: directory)
}

/// Saves a model by inserting or updating it in the type-derived store.
/// - Parameters:
///   - entity: The model to persist.
///   - directory: The base directory used for the store file.
public func save<Model: Codable & Identifiable & Sendable & Hashable>(
    _ entity: Model,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
) async throws where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: Model.self, directory: directory)
    try await store.upsert(entity)
}

/// Loads all persisted models for a type-derived store.
/// - Parameters:
///   - type: The model type.
///   - directory: The base directory used for the store file.
/// - Returns: All persisted models.
public func loadAll<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
) async throws -> [Model] where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: type, directory: directory)
    return try await store.all()
}

/// Loads all models matching a predicate from a type-derived store.
public func query<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
    where predicate: @Sendable (Model) -> Bool
) async throws -> [Model] where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: type, directory: directory)
    return try await store.filter(where: predicate)
}

/// Returns the first model matching a predicate from a type-derived store.
public func loadFirst<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
    where predicate: @Sendable (Model) -> Bool
) async throws -> Model? where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: type, directory: directory)
    return try await store.first(where: predicate)
}

/// Returns whether any model matches a predicate in a type-derived store.
public func contains<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
    where predicate: @Sendable (Model) -> Bool
) async throws -> Bool where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: type, directory: directory)
    return try await store.contains(where: predicate)
}

/// Returns the number of models matching a predicate in a type-derived store.
public func count<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
    where predicate: @Sendable (Model) -> Bool
) async throws -> Int where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: type, directory: directory)
    return try await store.count(where: predicate)
}

/// Loads a model by identifier from a type-derived store.
/// - Parameters:
///   - type: The model type.
///   - id: The model identifier.
///   - directory: The base directory used for the store file.
/// - Returns: The persisted model.
public func load<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    id: Model.ID,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
) async throws -> Model where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: type, directory: directory)
    return try await store.read(id: id)
}

/// Removes a model by identifier from a type-derived store.
/// - Parameters:
///   - type: The model type.
///   - id: The model identifier.
///   - directory: The base directory used for the store file.
public func remove<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    id: Model.ID,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
) async throws where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: type, directory: directory)
    try await store.delete(id: id)
}

/// Removes all models from a type-derived store.
/// - Parameters:
///   - type: The model type.
///   - directory: The base directory used for the store file.
public func removeAll<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
) async throws where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: type, directory: directory)
    try await store.deleteAll()
}

/// Returns a stream of snapshots for the type-derived store.
/// - Parameters:
///   - type: The model type.
///   - directory: The base directory used for the store file.
/// - Returns: A stream of full snapshots as the store changes.
public func stream<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
) async throws -> AsyncStream<[Model]> where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: type, directory: directory)
    return await store.stream
}

/// Returns a stream of snapshots for the type-derived store with custom buffering.
/// - Parameters:
///   - type: The model type.
///   - directory: The base directory used for the store file.
///   - bufferingPolicy: The buffering policy used for stream snapshots.
/// - Returns: A stream of full snapshots as the store changes.
public func stream<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
    bufferingPolicy: AsyncStream<[Model]>.Continuation.BufferingPolicy
) async throws -> AsyncStream<[Model]> where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: type, directory: directory)
    return await store.makeStream(bufferingPolicy: bufferingPolicy)
}
