//
//  InMemorySimpleStore.swift
//  SimpleStore
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation
@testable import SimpleStore

actor InMemorySimpleStore<Entity: Codable & Identifiable & Sendable & Hashable>: SimpleStoreProtocol where Entity.ID: Hashable & Sendable {
    typealias Identifier = Entity.ID

    private var byID: [Identifier: Entity]
    private var continuations: [UUID: AsyncStream<[Entity]>.Continuation]

    init(seed: [Entity] = []) {
        self.byID = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
        self.continuations = [:]
    }

    var stream: AsyncStream<[Entity]> {
        AsyncStream { continuation in
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
            throw SimpleStoreError.alreadyExists
        }
        byID[entity.id] = entity
        publish()
    }

    func update(_ entity: Entity) async throws {
        if byID[entity.id] == nil {
            throw SimpleStoreError.notFound
        }
        byID[entity.id] = entity
        publish()
    }

    func delete(id: Identifier) async throws {
        if byID.removeValue(forKey: id) == nil {
            throw SimpleStoreError.notFound
        }
        publish()
    }

    func delete(ids: [Identifier]) async throws {
        for id in ids where byID[id] == nil {
            throw SimpleStoreError.notFound
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

    func loadAll() async throws -> [Entity] {
        Array(byID.values)
    }

    func all() async throws -> [Entity] {
        Array(byID.values)
    }

    func read(id: Identifier) async throws -> Entity {
        guard let entity = byID[id] else {
            throw SimpleStoreError.notFound
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
