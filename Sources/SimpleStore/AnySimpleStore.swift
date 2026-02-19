//
//  AnySimpleStore.swift
//  SimpleStore
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation

/// Type-erased actor wrapper for `SimpleStoreProtocol`.
public actor AnySimpleStore<Entity: Codable & Identifiable & Sendable & Hashable>: SimpleStoreProtocol where Entity.ID: Hashable & Sendable {
    public typealias Identifier = Entity.ID

    private let streamProvider: @Sendable (AsyncStream<[Entity]>.Continuation.BufferingPolicy) -> AsyncStream<[Entity]>
    private let insertOperation: @Sendable (Entity) async throws -> Void
    private let upsertOperation: @Sendable (Entity) async throws -> Void
    private let updateOperation: @Sendable (Entity) async throws -> Void
    private let deleteByIDOperation: @Sendable (Identifier) async throws -> Void
    private let deleteByIDsOperation: @Sendable ([Identifier]) async throws -> Void
    private let deleteAllOperation: @Sendable () async throws -> Void
    private let replaceAllOperation: @Sendable ([Entity]) async throws -> Void
    private let loadAllOperation: @Sendable () async throws -> [Entity]
    private let allOperation: @Sendable () async throws -> [Entity]
    private let containsOperation: @Sendable (Identifier) async throws -> Bool
    private let existsOperation: @Sendable (Identifier) async throws -> Bool
    private let countOperation: @Sendable () async throws -> Int
    private let readByIDOperation: @Sendable (Identifier) async throws -> Entity

    /// Creates a type-erased store from a concrete `SimpleStoreProtocol` actor.
    /// - Parameter base: The concrete store to wrap.
    public init<S: SimpleStoreProtocol>(_ base: S) where S.Entity == Entity, S.Identifier == Identifier {
        self.streamProvider = { bufferingPolicy in
            AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
                Task {
                    let upstream = await base.makeStream(bufferingPolicy: bufferingPolicy)
                    for await snapshot in upstream {
                        continuation.yield(snapshot)
                    }
                    continuation.finish()
                }
            }
        }
        self.insertOperation = { entity in
            try await base.insert(entity)
        }
        self.upsertOperation = { entity in
            try await base.upsert(entity)
        }
        self.updateOperation = { entity in
            try await base.update(entity)
        }
        self.deleteByIDOperation = { id in
            try await base.delete(id: id)
        }
        self.deleteByIDsOperation = { ids in
            try await base.delete(ids: ids)
        }
        self.deleteAllOperation = {
            try await base.deleteAll()
        }
        self.replaceAllOperation = { entities in
            try await base.replaceAll(with: entities)
        }
        self.loadAllOperation = {
            try await base.loadAll()
        }
        self.allOperation = {
            try await base.all()
        }
        self.containsOperation = { id in
            try await base.contains(id: id)
        }
        self.existsOperation = { id in
            try await base.exists(id: id)
        }
        self.countOperation = {
            try await base.count()
        }
        self.readByIDOperation = { id in
            try await base.read(id: id)
        }
    }

    public var stream: AsyncStream<[Entity]> {
        streamProvider(.unbounded)
    }
    
    public func makeStream(
        bufferingPolicy: AsyncStream<[Entity]>.Continuation.BufferingPolicy
    ) -> AsyncStream<[Entity]> {
        streamProvider(bufferingPolicy)
    }

    public func insert(_ entity: Entity) async throws {
        try await insertOperation(entity)
    }
    
    public func upsert(_ entity: Entity) async throws {
        try await upsertOperation(entity)
    }

    public func update(_ entity: Entity) async throws {
        try await updateOperation(entity)
    }

    public func delete(id: Identifier) async throws {
        try await deleteByIDOperation(id)
    }

    public func delete(ids: [Identifier]) async throws {
        try await deleteByIDsOperation(ids)
    }

    public func deleteAll() async throws {
        try await deleteAllOperation()
    }
    
    public func replaceAll(with entities: [Entity]) async throws {
        try await replaceAllOperation(entities)
    }

    public func loadAll() async throws -> [Entity] {
        try await loadAllOperation()
    }

    public func all() async throws -> [Entity] {
        try await allOperation()
    }
    
    public func filter(where predicate: @Sendable (Entity) -> Bool) async throws -> [Entity] {
        let entities = try await allOperation()
        return entities.filter(predicate)
    }
    
    public func contains(id: Identifier) async throws -> Bool {
        try await containsOperation(id)
    }
    
    public func exists(id: Identifier) async throws -> Bool {
        try await existsOperation(id)
    }
    
    public func contains(where predicate: @Sendable (Entity) -> Bool) async throws -> Bool {
        let entities = try await allOperation()
        return entities.contains(where: predicate)
    }
    
    public func count() async throws -> Int {
        try await countOperation()
    }
    
    public func count(where predicate: @Sendable (Entity) -> Bool) async throws -> Int {
        let entities = try await allOperation()
        return entities.filter(predicate).count
    }

    public func read(id: Identifier) async throws -> Entity {
        try await readByIDOperation(id)
    }

    public func first(where predicate: @Sendable (Entity) -> Bool) async throws -> Entity? {
        let entities = try await allOperation()
        return entities.first(where: predicate)
    }
}
