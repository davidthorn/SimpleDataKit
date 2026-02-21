//
//  SimpleStoreFunctions.swift
//  SimpleStore
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation

actor GlobalStoreRegistry {
    static let shared = GlobalStoreRegistry()
    
    private var stores: [String: AnyObject]
    
    init() {
        self.stores = [:]
    }
    
    private func key<Model>(
        for type: Model.Type,
        directory: FileManager.SearchPathDirectory,
        name: String?
    ) -> String {
        let normalizedName: String
        if let rawName = name?.trimmingCharacters(in: .whitespacesAndNewlines), rawName.isEmpty == false {
            normalizedName = rawName
        } else {
            normalizedName = "__default__"
        }
        return "\(String(reflecting: type))|\(directory.rawValue)|\(normalizedName)"
    }
    
    func resolve<Model: Codable & Identifiable & Sendable & Hashable>(
        for type: Model.Type,
        directory: FileManager.SearchPathDirectory,
        name: String?
    ) throws -> AnySimpleStore<Model> where Model.ID: Hashable & Sendable {
        let key = key(for: type, directory: directory, name: name)
        if let existing = stores[key] as? AnySimpleStore<Model> {
            return existing
        }
        let created = try makeSimpleStore(for: type, directory: directory)
        let wrapped = AnySimpleStore(created)
        stores[key] = wrapped
        return wrapped
    }
    
    func register<Model: Codable & Identifiable & Sendable & Hashable, S: SimpleStoreProtocol>(
        _ store: S,
        for type: Model.Type,
        directory: FileManager.SearchPathDirectory,
        name: String?
    ) where S.Entity == Model, S.Identifier == Model.ID, Model.ID: Hashable & Sendable {
        let key = key(for: type, directory: directory, name: name)
        stores[key] = AnySimpleStore(store)
    }
    
    @discardableResult
    func unregister<Model: Codable & Identifiable & Sendable & Hashable>(
        for type: Model.Type,
        directory: FileManager.SearchPathDirectory,
        name: String?
    ) -> Bool where Model.ID: Hashable & Sendable {
        let key = key(for: type, directory: directory, name: name)
        return stores.removeValue(forKey: key) != nil
    }
}

public func resolveGlobalStore<Model: Codable & Identifiable & Sendable & Hashable>(
    for type: Model.Type,
    directory: FileManager.SearchPathDirectory,
    name: String? = nil
) async throws -> AnySimpleStore<Model> where Model.ID: Hashable & Sendable {
    try await GlobalStoreRegistry.shared.resolve(for: type, directory: directory, name: name)
}

/// Registers a global store instance used by global functional APIs for the model and directory key.
/// - Parameters:
///   - store: The store instance to register.
///   - type: The model type.
///   - directory: The search-path directory key for this registration.
public func registerGlobalStore<Model: Codable & Identifiable & Sendable & Hashable, S: SimpleStoreProtocol>(
    _ store: S,
    for type: Model.Type,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
    name: String? = nil
) async where S.Entity == Model, S.Identifier == Model.ID, Model.ID: Hashable & Sendable {
    await GlobalStoreRegistry.shared.register(store, for: type, directory: directory, name: name)
}

/// Unregisters a previously registered global store for the model and directory key.
/// - Parameters:
///   - type: The model type.
///   - directory: The search-path directory key for this registration.
/// - Returns: `true` when a store registration existed and was removed.
@discardableResult
public func unregisterGlobalStore<Model: Codable & Identifiable & Sendable & Hashable>(
    for type: Model.Type,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
    name: String? = nil
) async -> Bool where Model.ID: Hashable & Sendable {
    await GlobalStoreRegistry.shared.unregister(for: type, directory: directory, name: name)
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
@discardableResult
public func loadAll<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
) async throws -> [Model] where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: type, directory: directory)
    return try await store.all()
}

/// Returns the total number of models in a type-derived store.
public func count<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
) async throws -> Int where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: type, directory: directory)
    return try await store.count()
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

/// Returns whether a model with `id` exists in a type-derived store.
public func exists<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    id: Model.ID,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
) async throws -> Bool where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: type, directory: directory)
    return try await store.exists(id: id)
}

/// Deletes a model by identifier from a type-derived store.
/// - Parameters:
///   - type: The model type.
///   - id: The model identifier.
///   - directory: The base directory used for the store file.
public func delete<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    id: Model.ID,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
) async throws where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: type, directory: directory)
    try await store.delete(id: id)
}

/// Deletes all models from a type-derived store.
/// - Parameters:
///   - type: The model type.
///   - directory: The base directory used for the store file.
public func deleteAll<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
) async throws where Model.ID: Hashable & Sendable {
    let store = try await resolveGlobalStore(for: type, directory: directory)
    try await store.deleteAll()
}

@available(*, deprecated, renamed: "delete(_:id:directory:)")
public func remove<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    id: Model.ID,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
) async throws where Model.ID: Hashable & Sendable {
    try await delete(type, id: id, directory: directory)
}

@available(*, deprecated, renamed: "deleteAll(_:directory:)")
public func removeAll<Model: Codable & Identifiable & Sendable & Hashable>(
    _ type: Model.Type,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
) async throws where Model.ID: Hashable & Sendable {
    try await deleteAll(type, directory: directory)
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
