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

    /// Inserts a new model value.
    /// - Parameter entity: The model to insert.
    func insert(_ entity: Entity) async throws

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

    /// Loads all persisted model values from disk.
    /// - Returns: All loaded model values.
    func loadAll() async throws -> [Entity]

    /// Returns all persisted model values.
    func all() async throws -> [Entity]

    /// Reads a model value by identifier.
    /// - Parameter id: The identifier to read.
    /// - Returns: The model if found.
    /// - Throws: `SimpleStoreError.notFound` when the model does not exist.
    func read(id: Identifier) async throws -> Entity

    /// Returns the first model value matching the predicate.
    /// - Parameter predicate: The filter predicate.
    /// - Returns: The first matching model if found; otherwise `nil`.
    func first(where predicate: @Sendable (Entity) -> Bool) async throws -> Entity?
}
