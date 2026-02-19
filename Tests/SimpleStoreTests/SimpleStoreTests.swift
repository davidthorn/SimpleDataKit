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
        } catch let error as SimpleStore<SimpleStoreTestEntity>.StoreError {
            switch error {
            case .alreadyExists(id: entity.id):
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
        } catch let error as SimpleStore<SimpleStoreTestEntity>.StoreError {
            switch error {
            case .notFound(id: entity.id):
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
        } catch let error as SimpleStore<SimpleStoreTestEntity>.StoreError {
            switch error {
            case .notFound(id: entity.id):
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
        } catch let error as SimpleStore<SimpleStoreTestEntity>.StoreError {
            switch error {
            case .notFound(id: _):
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
        } catch let error as SimpleStore<SimpleStoreTestEntity>.StoreError {
            switch error {
            case .notFound(id: missingID):
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
        } catch let error as SimpleStore<SimpleStoreTestEntity>.StoreError {
            switch error {
            case .notFound(id: _):
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
        } catch let error as SimpleStore<SimpleStoreTestEntity>.StoreError {
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
        } catch let error as SimpleStore<SimpleStoreTestEntity>.StoreError {
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
        } catch let error as SimpleStore<SimpleStoreTestEntity>.StoreError {
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
        } catch let error as SimpleStore<SimpleStoreTestEntity>.StoreError {
            switch error {
            case .notFound(id: entity.id):
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
    
    @Test("upsert inserts then updates by id")
    func upsertInsertsThenUpdatesByID() async throws {
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: makeUniqueStoreFileURL())
        let id = UUID()
        let first = SimpleStoreTestEntity(id: id, name: "one", value: 1)
        let second = SimpleStoreTestEntity(id: id, name: "two", value: 2)
        
        try await store.upsert(first)
        try await store.upsert(second)
        
        let all = try await store.all()
        #expect(all.count == 1)
        #expect(all.first == second)
    }
    
    @Test("contains and count reflect store state")
    func containsAndCountReflectStoreState() async throws {
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: makeUniqueStoreFileURL())
        let entity = SimpleStoreTestEntity(id: UUID(), name: "item", value: 1)
        
        let initialCount = try await store.count()
        #expect(initialCount == 0)
        #expect(try await store.contains(id: entity.id) == false)
        
        try await store.insert(entity)
        #expect(try await store.count() == 1)
        #expect(try await store.contains(id: entity.id))
    }
    
    @Test("replaceAll overwrites existing state")
    func replaceAllOverwritesExistingState() async throws {
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: makeUniqueStoreFileURL())
        try await store.insert(SimpleStoreTestEntity(id: UUID(), name: "old", value: 1))
        
        let replacement = [
            SimpleStoreTestEntity(id: UUID(), name: "a", value: 10),
            SimpleStoreTestEntity(id: UUID(), name: "b", value: 20)
        ]
        try await store.replaceAll(with: replacement)
        
        let all = try await store.all()
        #expect(all == replacement)
    }
    
    @Test("StoreFactory creates file-based store in configured directory")
    func storeFactoryCreatesStoreInConfiguredDirectory() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SimpleStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        let factory = StoreFactory(directoryURL: directory)
        let store = factory.makeStore(for: SimpleStoreTestEntity.self, fileName: "entities.json")
        let entity = SimpleStoreTestEntity(id: UUID(), name: "factory", value: 5)
        try await store.insert(entity)
        
        let persistedURL = directory.appendingPathComponent("entities.json")
        #expect(FileManager.default.fileExists(atPath: persistedURL.path))
    }
    
    @Test("makeSimpleStore creates and persists in requested system directory")
    func makeSimpleStoreCreatesAndPersistsInRequestedSystemDirectory() async throws {
        let fileName = "simple-store-\(UUID().uuidString).json"
        let store = try makeSimpleStore(for: SimpleStoreTestEntity.self, fileName: fileName, directory: .cachesDirectory)
        let entity = SimpleStoreTestEntity(id: UUID(), name: "global", value: 8)
        try await store.insert(entity)
        
        let cachesURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let persistedURL = cachesURL.appendingPathComponent(fileName)
        #expect(FileManager.default.fileExists(atPath: persistedURL.path))
    }
    
    @Test("makeSimpleStore derives file name from model type")
    func makeSimpleStoreDerivesFileNameFromModelType() async throws {
        let store = try makeSimpleStore(for: SimpleStoreTestEntity.self, directory: .cachesDirectory)
        let entity = SimpleStoreTestEntity(id: UUID(), name: "typed", value: 3)
        try await store.insert(entity)
        
        let cachesURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let persistedURL = cachesURL.appendingPathComponent("SimpleStoreTestEntity.json")
        #expect(FileManager.default.fileExists(atPath: persistedURL.path))
    }
    
    @Test("global save and load APIs persist and read type records")
    func globalSaveAndLoadAPIsPersistAndReadTypeRecords() async throws {
        try await removeAll(SimpleStoreTestEntity.self, directory: .cachesDirectory)
        let entity = SimpleStoreTestEntity(id: UUID(), name: "global-api", value: 11)
        
        try await save(entity, directory: .cachesDirectory)
        
        let loaded = try await load(SimpleStoreTestEntity.self, id: entity.id, directory: .cachesDirectory)
        #expect(loaded == entity)
        
        let all = try await loadAll(SimpleStoreTestEntity.self, directory: .cachesDirectory)
        #expect(all.contains(entity))
    }
    
    @Test("global remove APIs delete records")
    func globalRemoveAPIsDeleteRecords() async throws {
        try await removeAll(SimpleStoreTestEntity.self, directory: .cachesDirectory)
        let first = SimpleStoreTestEntity(id: UUID(), name: "one", value: 1)
        let second = SimpleStoreTestEntity(id: UUID(), name: "two", value: 2)
        
        try await save(first, directory: .cachesDirectory)
        try await save(second, directory: .cachesDirectory)
        try await remove(SimpleStoreTestEntity.self, id: first.id, directory: .cachesDirectory)
        
        let remaining = try await loadAll(SimpleStoreTestEntity.self, directory: .cachesDirectory)
        #expect(remaining.contains(second))
        #expect(remaining.contains(first) == false)
        
        try await removeAll(SimpleStoreTestEntity.self, directory: .cachesDirectory)
        let empty = try await loadAll(SimpleStoreTestEntity.self, directory: .cachesDirectory)
        #expect(empty.isEmpty)
    }
    
    @Test("global stream emits initial and updated snapshots")
    func globalStreamEmitsInitialAndUpdatedSnapshots() async throws {
        try await removeAll(SimpleStoreTestEntity.self, directory: .cachesDirectory)
        let updates = try await stream(SimpleStoreTestEntity.self, directory: .cachesDirectory)
        var iterator = updates.makeAsyncIterator()
        
        let initial = await iterator.next()
        #expect(initial == [])
        
        let entity = SimpleStoreTestEntity(id: UUID(), name: "stream-global", value: 12)
        try await save(entity, directory: .cachesDirectory)
        
        var received = false
        for _ in 0..<3 {
            if let next = await iterator.next(), next.contains(entity) {
                received = true
                break
            }
        }
        #expect(received)
    }
    
    @Test("global stream with buffering policy emits snapshots")
    func globalStreamWithBufferingPolicyEmitsSnapshots() async throws {
        try await removeAll(SimpleStoreTestEntity.self, directory: .cachesDirectory)
        let updates = try await stream(
            SimpleStoreTestEntity.self,
            directory: .cachesDirectory,
            bufferingPolicy: .bufferingNewest(1)
        )
        var iterator = updates.makeAsyncIterator()
        
        let initial = await iterator.next()
        #expect(initial == [])
        
        let entity = SimpleStoreTestEntity(id: UUID(), name: "stream-buffered", value: 13)
        try await save(entity, directory: .cachesDirectory)
        
        var received = false
        for _ in 0..<3 {
            if let next = await iterator.next(), next.contains(entity) {
                received = true
                break
            }
        }
        #expect(received)
    }
    
    @Test("store query methods filter and predicate helpers")
    func storeQueryMethodsFilterAndPredicateHelpers() async throws {
        let store = SimpleStore<SimpleStoreTestEntity>(fileURL: makeUniqueStoreFileURL())
        try await store.insert(SimpleStoreTestEntity(id: UUID(), name: "a", value: 1))
        try await store.insert(SimpleStoreTestEntity(id: UUID(), name: "b", value: 2))
        try await store.insert(SimpleStoreTestEntity(id: UUID(), name: "b", value: 3))
        
        let filtered = try await store.filter { $0.name == "b" }
        #expect(filtered.count == 2)
        #expect(try await store.contains(where: { $0.value == 3 }))
        #expect(try await store.count(where: { $0.name == "b" }) == 2)
    }
    
    @Test("global query helpers return filtered results")
    func globalQueryHelpersReturnFilteredResults() async throws {
        try await removeAll(SimpleStoreTestEntity.self, directory: .cachesDirectory)
        try await save(SimpleStoreTestEntity(id: UUID(), name: "x", value: 1), directory: .cachesDirectory)
        try await save(SimpleStoreTestEntity(id: UUID(), name: "y", value: 2), directory: .cachesDirectory)
        
        let filtered = try await query(SimpleStoreTestEntity.self, directory: .cachesDirectory, where: { $0.name == "y" })
        #expect(filtered.count == 1)
        #expect(try await contains(SimpleStoreTestEntity.self, directory: .cachesDirectory, where: { $0.value == 2 }))
        #expect(try await count(SimpleStoreTestEntity.self, directory: .cachesDirectory, where: { $0.value >= 1 }) == 2)
        let first = try await loadFirst(SimpleStoreTestEntity.self, directory: .cachesDirectory, where: { $0.name == "x" })
        #expect(first?.name == "x")
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
