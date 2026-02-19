//
//  Persistable.swift
//  SimpleStore
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation

/// A model that can use `SimpleStore` global persistence APIs directly.
public protocol Persistable: Codable, Identifiable, Sendable, Hashable where ID: Hashable & Sendable {}

public extension Persistable {
    /// Persists this model by inserting or updating it.
    /// - Parameter directory: The persistence directory.
    func persist(
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
    ) async throws {
        let store = try await resolveGlobalStore(for: Self.self, directory: directory)
        try await store.upsert(self)
    }

    /// Deletes this model by identifier.
    /// - Parameter directory: The persistence directory.
    func delete(
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
    ) async throws {
        let store = try await resolveGlobalStore(for: Self.self, directory: directory)
        try await store.delete(id: id)
    }

    /// Loads all models of this type.
    /// - Parameter directory: The persistence directory.
    static func loadAll(
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
    ) async throws -> [Self] {
        let store = try await resolveGlobalStore(for: Self.self, directory: directory)
        return try await store.all()
    }

    /// Loads one model by identifier.
    /// - Parameters:
    ///   - id: The identifier to read.
    ///   - directory: The persistence directory.
    static func load(
        id: ID,
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
    ) async throws -> Self {
        let store = try await resolveGlobalStore(for: Self.self, directory: directory)
        return try await store.read(id: id)
    }
    
    /// Returns whether this model currently exists in persistence.
    /// - Parameter directory: The persistence directory.
    func exists(
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
    ) async throws -> Bool {
        let store = try await resolveGlobalStore(for: Self.self, directory: directory)
        return try await store.exists(id: id)
    }
    
    /// Returns whether any model matches the receiver as a predicate target.
    /// - Parameters:
    ///   - directory: The persistence directory.
    ///   - predicate: The predicate to evaluate.
    func contains(
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
        where predicate: @Sendable (Self) -> Bool
    ) async throws -> Bool {
        let store = try await resolveGlobalStore(for: Self.self, directory: directory)
        return try await store.contains(where: predicate)
    }

    /// Removes all models of this type.
    /// - Parameter directory: The persistence directory.
    static func removeAll(
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
    ) async throws {
        let store = try await resolveGlobalStore(for: Self.self, directory: directory)
        try await store.deleteAll()
    }

    /// Returns a stream of snapshots for this model type.
    /// - Parameter directory: The persistence directory.
    static func stream(
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
    ) async throws -> AsyncStream<[Self]> {
        let store = try await resolveGlobalStore(for: Self.self, directory: directory)
        return await store.stream
    }

    /// Returns a stream of snapshots for this model type with custom buffering.
    /// - Parameters:
    ///   - directory: The persistence directory.
    ///   - bufferingPolicy: The buffering policy for snapshots.
    static func stream(
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
        bufferingPolicy: AsyncStream<[Self]>.Continuation.BufferingPolicy
    ) async throws -> AsyncStream<[Self]> {
        let store = try await resolveGlobalStore(for: Self.self, directory: directory)
        return await store.makeStream(bufferingPolicy: bufferingPolicy)
    }

    /// Returns all models matching a predicate.
    /// - Parameters:
    ///   - directory: The persistence directory.
    ///   - predicate: The filter predicate.
    static func query(
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
        where predicate: @Sendable (Self) -> Bool
    ) async throws -> [Self] {
        let store = try await resolveGlobalStore(for: Self.self, directory: directory)
        return try await store.filter(where: predicate)
    }

    /// Returns the first model matching a predicate.
    /// - Parameters:
    ///   - directory: The persistence directory.
    ///   - predicate: The filter predicate.
    static func loadFirst(
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
        where predicate: @Sendable (Self) -> Bool
    ) async throws -> Self? {
        let store = try await resolveGlobalStore(for: Self.self, directory: directory)
        return try await store.first(where: predicate)
    }

    /// Returns whether any model matches a predicate.
    /// - Parameters:
    ///   - directory: The persistence directory.
    ///   - predicate: The filter predicate.
    static func contains(
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
        where predicate: @Sendable (Self) -> Bool
    ) async throws -> Bool {
        let store = try await resolveGlobalStore(for: Self.self, directory: directory)
        return try await store.contains(where: predicate)
    }

    /// Returns the total number of models.
    /// - Parameter directory: The persistence directory.
    static func count(
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
    ) async throws -> Int {
        let store = try await resolveGlobalStore(for: Self.self, directory: directory)
        return try await store.count()
    }

    /// Returns the number of models matching a predicate.
    /// - Parameters:
    ///   - directory: The persistence directory.
    ///   - predicate: The filter predicate.
    static func count(
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
        where predicate: @Sendable (Self) -> Bool
    ) async throws -> Int {
        let store = try await resolveGlobalStore(for: Self.self, directory: directory)
        return try await store.count(where: predicate)
    }
}
