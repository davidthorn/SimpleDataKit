//
//  InMemorySimpleStore.swift
//  SimpleStore
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation
@testable import SimpleStore

private enum InMemorySimpleStoreError: Error {
    case notFound
    case alreadyExists
}

actor InMemorySimpleStore<Entity: Codable & Identifiable & Sendable & Hashable>: SimpleStoreProtocol where Entity.ID: Hashable & Sendable {
    typealias Identifier = Entity.ID

    private var byID: [Identifier: Entity]
    private var continuations: [UUID: AsyncStream<[Entity]>.Continuation]

    init(seed: [Entity] = []) {
        self.byID = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
        self.continuations = [:]
    }

    var stream: AsyncStream<[Entity]> {
        makeStream(bufferingPolicy: .unbounded)
    }
    
    func makeStream(
        bufferingPolicy: AsyncStream<[Entity]>.Continuation.BufferingPolicy
    ) -> AsyncStream<[Entity]> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            let id = UUID()
            continuations[id] = continuation
            continuation.yield(Array(byID.values))
            continuation.onTermination = { [id] _ in
                Task {
                    await self.removeContinuation(id: id)
                }
            }
        }
    }

    func insert(_ entity: Entity) async throws {
        if byID[entity.id] != nil {
            throw InMemorySimpleStoreError.alreadyExists
        }
        byID[entity.id] = entity
        publish()
    }
    
    func upsert(_ entity: Entity) async throws {
        byID[entity.id] = entity
        publish()
    }

    func update(_ entity: Entity) async throws {
        if byID[entity.id] == nil {
            throw InMemorySimpleStoreError.notFound
        }
        byID[entity.id] = entity
        publish()
    }

    func delete(id: Identifier) async throws {
        if byID.removeValue(forKey: id) == nil {
            throw InMemorySimpleStoreError.notFound
        }
        publish()
    }

    func delete(ids: [Identifier]) async throws {
        for id in ids where byID[id] == nil {
            throw InMemorySimpleStoreError.notFound
        }
        for id in ids {
            byID.removeValue(forKey: id)
        }
        publish()
    }

    func deleteAll() async throws {
        byID.removeAll(keepingCapacity: false)
        publish()
    }
    
    func replaceAll(with entities: [Entity]) async throws {
        byID = Dictionary(uniqueKeysWithValues: entities.map { ($0.id, $0) })
        publish()
    }

    func loadAll() async throws -> [Entity] {
        Array(byID.values)
    }

    func all() async throws -> [Entity] {
        Array(byID.values)
    }
    
    func filter(where predicate: @Sendable (Entity) -> Bool) async throws -> [Entity] {
        Array(byID.values).filter(predicate)
    }
    
    func contains(id: Identifier) async throws -> Bool {
        byID[id] != nil
    }
    
    func contains(where predicate: @Sendable (Entity) -> Bool) async throws -> Bool {
        Array(byID.values).contains(where: predicate)
    }
    
    func count() async throws -> Int {
        byID.count
    }
    
    func count(where predicate: @Sendable (Entity) -> Bool) async throws -> Int {
        Array(byID.values).filter(predicate).count
    }

    func read(id: Identifier) async throws -> Entity {
        guard let entity = byID[id] else {
            throw InMemorySimpleStoreError.notFound
        }
        return entity
    }

    func first(where predicate: @Sendable (Entity) -> Bool) async throws -> Entity? {
        Array(byID.values).first(where: predicate)
    }

    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }

    private func publish() {
        let all = Array(byID.values)
        for continuation in continuations.values {
            continuation.yield(all)
        }
    }
}
