//
//  SimpleStore.swift
//  SimpleStore
//
//  Created by David Thorn on 18.02.2026.
//

import Foundation

public actor SimpleStore<Entity: Codable & Identifiable & Sendable & Hashable>: SimpleStoreProtocol where Entity.ID: Hashable & Sendable {
    public typealias Identifier = Entity.ID
    
    /// Errors thrown by `SimpleStore`.
    public enum StoreError: Error {
        /// The requested model does not exist.
        /// - Parameter id: The identifier that was requested.
        case notFound(id: Identifier)
        
        /// The model already exists and cannot be inserted again.
        /// - Parameter id: The identifier that already exists.
        case alreadyExists(id: Identifier)
        
        /// The persisted data could not be encoded.
        case encodingFailed
        
        /// The persisted data could not be decoded.
        case decodingFailed
        
        /// The file system operation failed.
        case fileSystemOperationFailed
        
        /// An uncategorized error occurred.
        case unknown(error: Error)
    }

    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var entitiesByID: [Identifier: Entity]
    private var orderedIDs: [Identifier]
    private var hasLoadedFromDisk: Bool
    private var continuations: [UUID: AsyncStream<[Entity]>.Continuation]

    public init(
        fileURL: URL,
        fileManager: FileManager = .default,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.encoder = encoder
        self.decoder = decoder
        self.entitiesByID = [:]
        self.orderedIDs = []
        self.hasLoadedFromDisk = false
        self.continuations = [:]
    }
    
    /// Creates a store using a file name in a standard search-path directory.
    /// - Parameters:
    ///   - fileName: The file name used for persistence.
    ///   - directory: The base directory in which to place the file.
    ///   - fileManager: The file manager used for file operations.
    ///   - encoder: The JSON encoder used for persistence.
    ///   - decoder: The JSON decoder used for loading.
    public init(
        fileName: String,
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        fileManager: FileManager = .default,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) throws {
        let baseURL = try fileManager.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = baseURL.appendingPathComponent(fileName)
        self.init(fileURL: fileURL, fileManager: fileManager, encoder: encoder, decoder: decoder)
    }

    public var stream: AsyncStream<[Entity]> {
        makeStream(bufferingPolicy: .unbounded)
    }
    
    public func makeStream(
        bufferingPolicy: AsyncStream<[Entity]>.Continuation.BufferingPolicy
    ) -> AsyncStream<[Entity]> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            let continuationID = UUID()
            continuation.onTermination = { [continuationID] _ in
                Task {
                    await self.removeContinuation(id: continuationID)
                }
            }
            continuation.yield(snapshot())
            continuations[continuationID] = continuation
        }
    }

    public func insert(_ entity: Entity) async throws {
        try await ensureLoadedFromDisk()
        guard entitiesByID[entity.id] == nil else {
            throw StoreError.alreadyExists(id: entity.id)
        }

        entitiesByID[entity.id] = entity
        orderedIDs.append(entity.id)
        try persistToDisk()
        broadcastSnapshot()
    }
    
    public func upsert(_ entity: Entity) async throws {
        try await ensureLoadedFromDisk()
        let exists = entitiesByID[entity.id] != nil
        entitiesByID[entity.id] = entity
        if exists == false {
            orderedIDs.append(entity.id)
        }
        try persistToDisk()
        broadcastSnapshot()
    }

    public func update(_ entity: Entity) async throws {
        try await ensureLoadedFromDisk()
        guard entitiesByID[entity.id] != nil else {
            throw StoreError.notFound(id: entity.id)
        }

        entitiesByID[entity.id] = entity
        try persistToDisk()
        broadcastSnapshot()
    }

    public func delete(id: Identifier) async throws {
        try await ensureLoadedFromDisk()
        guard entitiesByID.removeValue(forKey: id) != nil else {
            throw StoreError.notFound(id: id)
        }
        if let index = orderedIDs.firstIndex(of: id) {
            orderedIDs.remove(at: index)
        }

        try persistToDisk()
        broadcastSnapshot()
    }

    public func delete(ids: [Identifier]) async throws {
        try await ensureLoadedFromDisk()

        for id in ids {
            guard entitiesByID[id] != nil else {
                throw StoreError.notFound(id: id)
            }
        }

        for id in ids {
            entitiesByID.removeValue(forKey: id)
        }
        let idsToDelete = Set(ids)
        orderedIDs.removeAll(where: { idsToDelete.contains($0) })

        try persistToDisk()
        broadcastSnapshot()
    }

    public func deleteAll() async throws {
        try await ensureLoadedFromDisk()
        entitiesByID.removeAll(keepingCapacity: false)
        orderedIDs.removeAll(keepingCapacity: false)
        try persistToDisk()
        broadcastSnapshot()
    }
    
    public func replaceAll(with entities: [Entity]) async throws {
        entitiesByID = Dictionary(uniqueKeysWithValues: entities.map { ($0.id, $0) })
        orderedIDs = entities.map { $0.id }
        hasLoadedFromDisk = true
        try persistToDisk()
        broadcastSnapshot()
    }

    public func loadAll() async throws -> [Entity] {
        let loaded = try readAllFromDisk()
        entitiesByID = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        orderedIDs = loaded.map { $0.id }
        hasLoadedFromDisk = true
        let all = snapshot()
        broadcastSnapshot()
        return all
    }

    public func all() async throws -> [Entity] {
        try await ensureLoadedFromDisk()
        return snapshot()
    }
    
    public func filter(where predicate: @Sendable (Entity) -> Bool) async throws -> [Entity] {
        try await ensureLoadedFromDisk()
        return snapshot().filter(predicate)
    }
    
    public func contains(id: Identifier) async throws -> Bool {
        try await ensureLoadedFromDisk()
        return entitiesByID[id] != nil
    }
    
    public func exists(id: Identifier) async throws -> Bool {
        try await contains(id: id)
    }
    
    public func contains(where predicate: @Sendable (Entity) -> Bool) async throws -> Bool {
        try await ensureLoadedFromDisk()
        return snapshot().contains(where: predicate)
    }
    
    public func count() async throws -> Int {
        try await ensureLoadedFromDisk()
        return entitiesByID.count
    }
    
    public func count(where predicate: @Sendable (Entity) -> Bool) async throws -> Int {
        try await ensureLoadedFromDisk()
        return snapshot().filter(predicate).count
    }

    public func read(id: Identifier) async throws -> Entity {
        try await ensureLoadedFromDisk()
        guard let entity = entitiesByID[id] else {
            throw StoreError.notFound(id: id)
        }
        return entity
    }

    public func first(where predicate: @Sendable (Entity) -> Bool) async throws -> Entity? {
        try await ensureLoadedFromDisk()
        return snapshot().first(where: predicate)
    }

    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }

    private func ensureLoadedFromDisk() async throws {
        guard hasLoadedFromDisk == false else {
            return
        }
        _ = try await loadAll()
    }

    private func snapshot() -> [Entity] {
        var result: [Entity] = []
        result.reserveCapacity(orderedIDs.count)
        for id in orderedIDs {
            if let entity = entitiesByID[id] {
                result.append(entity)
            }
        }
        return result
    }

    private func broadcastSnapshot() {
        let all = snapshot()
        for continuation in continuations.values {
            continuation.yield(all)
        }
    }

    private func persistToDisk() throws {
        do {
            let data = try encoder.encode(snapshot())
            try ensureStoreDirectoryExists()
            try data.write(to: fileURL, options: .atomic)
        } catch is EncodingError {
            throw StoreError.encodingFailed
        } catch {
            throw mapUnknown(error)
        }
    }

    private func readAllFromDisk() throws -> [Entity] {
        do {
            if fileManager.fileExists(atPath: fileURL.path) == false {
                return []
            }

            let data = try Data(contentsOf: fileURL)
            if data.isEmpty {
                return []
            }

            return try decoder.decode([Entity].self, from: data)
        } catch is DecodingError {
            throw StoreError.decodingFailed
        } catch {
            throw mapUnknown(error)
        }
    }

    private func ensureStoreDirectoryExists() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        if fileManager.fileExists(atPath: directoryURL.path) == false {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                throw StoreError.fileSystemOperationFailed
            }
        }
    }

    private func mapUnknown(_ error: Error) -> StoreError {
        if let simpleStoreError = error as? StoreError {
            return simpleStoreError
        }
        return .unknown(error: error)
    }
}
