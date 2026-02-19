//
//  SimpleStoreTests.swift
//  SimpleStore
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation
import Testing
@testable import SimpleStore

@Suite("SimpleStore", .serialized)
struct SimpleStoreTests {
    @Test("insert then read returns entity")
    func insertThenReadReturnsEntity() async throws {
        let url = makeUniqueStoreFileURL()
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)
        let entity = SimpleStoreTestEntity(id: UUID(), name: "alpha", value: 1)

        try await store.insert(entity)
        let readEntity = try await store.read(id: entity.id)

        #expect(readEntity == entity)
    }

    @Test("insert duplicate throws alreadyExists")
    func insertDuplicateThrowsAlreadyExists() async throws {
        let url = makeUniqueStoreFileURL()
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)
        let entity = SimpleStoreTestEntity(id: UUID(), name: "alpha", value: 1)

        try await store.insert(entity)

        do {
            try await store.insert(entity)
            Issue.record("Expected .alreadyExists")
        } catch let error as SimpleStoreError {
            switch error {
            case .alreadyExists:
                break
            default:
                Issue.record("Expected .alreadyExists, got \(String(describing: error))")
            }
        }
    }

    @Test("update existing entity persists new value")
    func updateExistingEntityPersistsNewValue() async throws {
        let url = makeUniqueStoreFileURL()
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)
        let id = UUID()
        let first = SimpleStoreTestEntity(id: id, name: "alpha", value: 1)
        let updated = SimpleStoreTestEntity(id: id, name: "beta", value: 2)

        try await store.insert(first)
        try await store.update(updated)

        let readEntity = try await store.read(id: id)
        #expect(readEntity == updated)
    }

    @Test("update missing throws notFound")
    func updateMissingThrowsNotFound() async throws {
        let url = makeUniqueStoreFileURL()
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)
        let entity = SimpleStoreTestEntity(id: UUID(), name: "missing", value: 10)

        do {
            try await store.update(entity)
            Issue.record("Expected .notFound")
        } catch let error as SimpleStoreError {
            switch error {
            case .notFound:
                break
            default:
                Issue.record("Expected .notFound, got \(String(describing: error))")
            }
        }
    }

    @Test("delete by id removes entity")
    func deleteByIDRemovesEntity() async throws {
        let url = makeUniqueStoreFileURL()
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)
        let entity = SimpleStoreTestEntity(id: UUID(), name: "alpha", value: 1)

        try await store.insert(entity)
        try await store.delete(id: entity.id)

        do {
            _ = try await store.read(id: entity.id)
            Issue.record("Expected .notFound")
        } catch let error as SimpleStoreError {
            switch error {
            case .notFound:
                break
            default:
                Issue.record("Expected .notFound, got \(String(describing: error))")
            }
        }
    }

    @Test("delete by id missing throws notFound")
    func deleteByIDMissingThrowsNotFound() async throws {
        let url = makeUniqueStoreFileURL()
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)

        do {
            try await store.delete(id: UUID())
            Issue.record("Expected .notFound")
        } catch let error as SimpleStoreError {
            switch error {
            case .notFound:
                break
            default:
                Issue.record("Expected .notFound, got \(String(describing: error))")
            }
        }
    }

    @Test("delete ids removes all specified entities")
    func deleteIDsRemovesSpecifiedEntities() async throws {
        let url = makeUniqueStoreFileURL()
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)
        let first = SimpleStoreTestEntity(id: UUID(), name: "a", value: 1)
        let second = SimpleStoreTestEntity(id: UUID(), name: "b", value: 2)
        let third = SimpleStoreTestEntity(id: UUID(), name: "c", value: 3)

        try await store.insert(first)
        try await store.insert(second)
        try await store.insert(third)

        try await store.delete(ids: [first.id, third.id])
        let all = try await store.all()

        #expect(Set(all) == Set([second]))
    }

    @Test("delete ids throws notFound when any id is missing")
    func deleteIDsThrowsWhenAnyIDIsMissing() async throws {
        let url = makeUniqueStoreFileURL()
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)
        let existing = SimpleStoreTestEntity(id: UUID(), name: "a", value: 1)
        let missingID = UUID()

        try await store.insert(existing)

        do {
            try await store.delete(ids: [existing.id, missingID])
            Issue.record("Expected .notFound")
        } catch let error as SimpleStoreError {
            switch error {
            case .notFound:
                break
            default:
                Issue.record("Expected .notFound, got \(String(describing: error))")
            }
        }

        let all = try await store.all()
        #expect(Set(all) == Set([existing]))
    }

    @Test("deleteAll clears store")
    func deleteAllClearsStore() async throws {
        let url = makeUniqueStoreFileURL()
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)

        try await store.insert(SimpleStoreTestEntity(id: UUID(), name: "a", value: 1))
        try await store.insert(SimpleStoreTestEntity(id: UUID(), name: "b", value: 2))
        try await store.deleteAll()

        let all = try await store.all()
        #expect(all.isEmpty)
    }

    @Test("all loads persisted values from disk")
    func allLoadsPersistedValuesFromDisk() async throws {
        let url = makeUniqueStoreFileURL()
        let seed = [
            SimpleStoreTestEntity(id: UUID(), name: "a", value: 1),
            SimpleStoreTestEntity(id: UUID(), name: "b", value: 2)
        ]

        let data = try JSONEncoder().encode(seed)
        try createDirectoryIfNeeded(for: url)
        try data.write(to: url, options: .atomic)

        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)
        let all = try await store.all()

        #expect(Set(all) == Set(seed))
    }

    @Test("loadAll returns empty when on-disk file is empty")
    func loadAllReturnsEmptyWhenOnDiskFileIsEmpty() async throws {
        let url = makeUniqueStoreFileURL()
        try createDirectoryIfNeeded(for: url)
        try Data().write(to: url, options: .atomic)

        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)
        let loaded = try await store.loadAll()

        #expect(loaded.isEmpty)
        let all = try await store.all()
        #expect(all.isEmpty)
    }

    @Test("loadAll refreshes in-memory state from disk")
    func loadAllRefreshesInMemoryStateFromDisk() async throws {
        let url = makeUniqueStoreFileURL()
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)

        let initial = SimpleStoreTestEntity(id: UUID(), name: "initial", value: 1)
        try await store.insert(initial)

        let replacement = [SimpleStoreTestEntity(id: UUID(), name: "replacement", value: 9)]
        let data = try JSONEncoder().encode(replacement)
        try data.write(to: url, options: .atomic)

        let loaded = try await store.loadAll()
        #expect(Set(loaded) == Set(replacement))

        let all = try await store.all()
        #expect(Set(all) == Set(replacement))
    }

    @Test("read missing throws notFound")
    func readMissingThrowsNotFound() async throws {
        let url = makeUniqueStoreFileURL()
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)

        do {
            _ = try await store.read(id: UUID())
            Issue.record("Expected .notFound")
        } catch let error as SimpleStoreError {
            switch error {
            case .notFound:
                break
            default:
                Issue.record("Expected .notFound, got \(String(describing: error))")
            }
        }
    }

    @Test("first returns first matching entity")
    func firstReturnsMatchingEntity() async throws {
        let url = makeUniqueStoreFileURL()
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)
        let a = SimpleStoreTestEntity(id: UUID(), name: "alpha", value: 1)
        let b = SimpleStoreTestEntity(id: UUID(), name: "beta", value: 2)

        try await store.insert(a)
        try await store.insert(b)

        let match = try await store.first { $0.name == "beta" }
        #expect(match == b)
    }

    @Test("first returns nil when no entity matches")
    func firstReturnsNilWhenNoEntityMatches() async throws {
        let url = makeUniqueStoreFileURL()
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)

        try await store.insert(SimpleStoreTestEntity(id: UUID(), name: "alpha", value: 1))

        let match = try await store.first { $0.name == "nope" }
        #expect(match == nil)
    }

    @Test("stream emits initial and updated snapshots")
    func streamEmitsInitialAndUpdatedSnapshots() async throws {
        let url = makeUniqueStoreFileURL()
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)

        let stream = await store.stream
        var iterator = stream.makeAsyncIterator()

        let initial = await iterator.next()
        #expect(initial == [])

        let entity = SimpleStoreTestEntity(id: UUID(), name: "alpha", value: 1)
        try await store.insert(entity)

        var foundUpdatedSnapshot = false
        for _ in 0..<3 {
            if let next = await iterator.next(), Set(next) == Set([entity]) {
                foundUpdatedSnapshot = true
                break
            }
        }

        #expect(foundUpdatedSnapshot)
    }

    @Test("invalid on-disk JSON throws decodingFailed")
    func invalidOnDiskJSONThrowsDecodingFailed() async throws {
        let url = makeUniqueStoreFileURL()
        try createDirectoryIfNeeded(for: url)
        try Data("not-json".utf8).write(to: url, options: .atomic)

        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)

        do {
            _ = try await store.loadAll()
            Issue.record("Expected .decodingFailed")
        } catch let error as SimpleStoreError {
            switch error {
            case .decodingFailed:
                break
            default:
                Issue.record("Expected .decodingFailed, got \(String(describing: error))")
            }
        }
    }

    @Test("encoding failure throws encodingFailed")
    func encodingFailureThrowsEncodingFailed() async throws {
        let url = makeUniqueStoreFileURL()
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: url)
        let invalid = SimpleStoreTestEntity(id: UUID(), name: "nan", value: .nan)

        do {
            try await store.insert(invalid)
            Issue.record("Expected .encodingFailed")
        } catch let error as SimpleStoreError {
            switch error {
            case .encodingFailed:
                break
            default:
                Issue.record("Expected .encodingFailed, got \(String(describing: error))")
            }
        }
    }

    @Test("filesystem setup failure throws fileSystemOperationFailed")
    func fileSystemSetupFailureThrowsFileSystemOperationFailed() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("SimpleStoreTests-\(UUID().uuidString)", isDirectory: true)
        let parentFileURL = root.appendingPathComponent("parent-file")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("x".utf8).write(to: parentFileURL, options: .atomic)

        let badStoreURL = parentFileURL
            .appendingPathComponent("child", isDirectory: true)
            .appendingPathComponent("store.json")
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: badStoreURL)

        do {
            try await store.insert(SimpleStoreTestEntity(id: UUID(), name: "a", value: 1))
            Issue.record("Expected .fileSystemOperationFailed")
        } catch let error as SimpleStoreError {
            switch error {
            case .fileSystemOperationFailed:
                break
            default:
                Issue.record("Expected .fileSystemOperationFailed, got \(String(describing: error))")
            }
        }
    }

    @Test("AnySimpleStore forwards CRUD to wrapped store")
    func anySimpleStoreForwardsCRUDToWrappedStore() async throws {
        let url = makeUniqueStoreFileURL()
        let base = SimpleStore<SimpleStoreTestEntity>(fileURL: url)
        let erased = AnySimpleStore(base)
        let entity = SimpleStoreTestEntity(id: UUID(), name: "wrapped", value: 42)
        try await erased.insert(entity)
        let readEntity = try await erased.read(id: entity.id)
        #expect(readEntity == entity)

        try await erased.delete(id: entity.id)
        do {
            _ = try await erased.read(id: entity.id)
            Issue.record("Expected .notFound")
        } catch let error as SimpleStoreError {
            switch error {
            case .notFound:
                break
            default:
                Issue.record("Expected .notFound, got \(String(describing: error))")
            }
        }
    }

    @Test("AnySimpleStore enables uniform handling of different store implementations")
    func anySimpleStoreEnablesUniformHandlingOfDifferentStoreImplementations() async throws {
        let entityA = SimpleStoreTestEntity(id: UUID(), name: "disk", value: 1)
        let entityB = SimpleStoreTestEntity(id: UUID(), name: "memory", value: 2)

        let diskStore = AnySimpleStore(SimpleStore<SimpleStoreTestEntity>(fileURL: makeUniqueStoreFileURL()))
        let memoryStore = AnySimpleStore(InMemorySimpleStore<SimpleStoreTestEntity>())
        let stores = [diskStore, memoryStore]

        try await stores[0].insert(entityA)
        try await stores[1].insert(entityB)

        let firstAll = try await stores[0].all()
        let secondAll = try await stores[1].all()
        #expect(Set(firstAll) == Set([entityA]))
        #expect(Set(secondAll) == Set([entityB]))
    }

    @Test("AnySimpleStore forwards stream snapshots")
    func anySimpleStoreForwardsStreamSnapshots() async throws {
        let erased = AnySimpleStore(InMemorySimpleStore<SimpleStoreTestEntity>())
        let stream = await erased.stream
        var iterator = stream.makeAsyncIterator()

        let initial = await iterator.next()
        #expect(initial == [])

        let entity = SimpleStoreTestEntity(id: UUID(), name: "stream", value: 7)
        try await erased.insert(entity)

        var receivedUpdated = false
        for _ in 0..<3 {
            if let next = await iterator.next(), Set(next) == Set([entity]) {
                receivedUpdated = true
                break
            }
        }
        #expect(receivedUpdated)
    }
}

private func makeUniqueStoreFileURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("SimpleStoreTests-\(UUID().uuidString)", isDirectory: true)
        .appendingPathComponent("store.json")
}

private func createDirectoryIfNeeded(for fileURL: URL) throws {
    let directoryURL = fileURL.deletingLastPathComponent()
    if FileManager.default.fileExists(atPath: directoryURL.path) == false {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
}
