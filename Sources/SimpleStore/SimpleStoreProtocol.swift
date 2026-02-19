//
//  SimpleStoreProtocol.swift
//  SimpleStore
//
//  Created by David Thorn on 18.02.2026.
//

import Foundation

/// Defines the public API for a file-backed CRUD store.
public protocol SimpleStoreProtocol: Actor, Sendable {
    /// The persisted model type.
    associatedtype Entity: Codable & Identifiable & Sendable & Hashable

    /// The identifier type used by the persisted model.
    associatedtype Identifier: Hashable & Sendable = Entity.ID where Entity.ID == Identifier

    /// Emits a full snapshot whenever store contents change.
    var stream: AsyncStream<[Entity]> { get }
    
    /// Emits full snapshots using a custom buffering policy.
    /// - Parameter bufferingPolicy: The buffering policy used for stream snapshots.
    func makeStream(
        bufferingPolicy: AsyncStream<[Entity]>.Continuation.BufferingPolicy
    ) -> AsyncStream<[Entity]>

    /// Inserts a new model value.
    /// - Parameter entity: The model to insert.
    /// - Throws: `SimpleStore.StoreError.alreadyExists(id:)` with `entity.id`
    ///   when a model with the same identifier already exists.
    func insert(_ entity: Entity) async throws
    
    /// Inserts or updates a model value.
    /// - Parameter entity: The model to insert or update.
    func upsert(_ entity: Entity) async throws

    /// Updates an existing model value.
    /// - Parameter entity: The model to update.
    func update(_ entity: Entity) async throws

    /// Deletes a model value by identifier.
    /// - Parameter id: The identifier to delete.
    func delete(id: Identifier) async throws

    /// Deletes multiple model values by identifiers.
    /// - Parameter ids: The identifiers to delete.
    func delete(ids: [Identifier]) async throws

    /// Deletes all model values.
    func deleteAll() async throws
    
    /// Replaces all model values in the store.
    /// - Parameter entities: The full set of model values to persist.
    func replaceAll(with entities: [Entity]) async throws

    /// Loads all persisted model values from disk.
    /// - Returns: All loaded model values.
    func loadAll() async throws -> [Entity]

    /// Returns all persisted model values.
    func all() async throws -> [Entity]
    
    /// Returns all model values matching a predicate.
    /// - Parameter predicate: The filter predicate.
    func filter(where predicate: @Sendable (Entity) -> Bool) async throws -> [Entity]
    
    /// Returns whether a model with `id` exists.
    /// - Parameter id: The identifier to check.
    func contains(id: Identifier) async throws -> Bool
    
    /// Returns whether a model with `id` exists.
    /// - Parameter id: The identifier to check.
    func exists(id: Identifier) async throws -> Bool
    
    /// Returns whether any model matches a predicate.
    /// - Parameter predicate: The predicate to evaluate.
    func contains(where predicate: @Sendable (Entity) -> Bool) async throws -> Bool
    
    /// Returns the number of persisted model values.
    func count() async throws -> Int
    
    /// Returns the number of model values matching a predicate.
    /// - Parameter predicate: The predicate to evaluate.
    func count(where predicate: @Sendable (Entity) -> Bool) async throws -> Int

    /// Reads a model value by identifier.
    /// - Parameter id: The identifier to read.
    /// - Returns: The model if found.
    /// - Throws: `SimpleStore.StoreError.notFound(id:)` with the requested `id`
    ///   when the model does not exist.
    func read(id: Identifier) async throws -> Entity

    /// Returns the first model value matching the predicate.
    /// - Parameter predicate: The filter predicate.
    /// - Returns: The first matching model if found; otherwise `nil`.
    func first(where predicate: @Sendable (Entity) -> Bool) async throws -> Entity?
}
