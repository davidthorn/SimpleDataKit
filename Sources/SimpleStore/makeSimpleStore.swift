//
//  makeSimpleStore.swift
//  SimpleStore
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation

/// Creates a `SimpleStore` using a file name and standard system directory.
/// - Parameters:
///   - type: The model type to persist.
///   - fileName: The file name used for persistence.
///   - directory: The base directory in which to create the store file.
/// - Returns: A configured `SimpleStore`.
public func makeSimpleStore<Model: Codable & Identifiable & Sendable & Hashable>(
    for type: Model.Type,
    fileName: String,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
) throws -> SimpleStore<Model> where Model.ID: Hashable & Sendable {
    let factory = try StoreFactory(directory: directory)
    return factory.makeStore(for: type, fileName: fileName)
}

/// Creates a `SimpleStore` using a type-derived file name in a standard system directory.
/// - Parameters:
///   - type: The model type to persist.
///   - directory: The base directory in which to create the store file.
/// - Returns: A configured `SimpleStore`.
public func makeSimpleStore<Model: Codable & Identifiable & Sendable & Hashable>(
    for type: Model.Type,
    directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
) throws -> SimpleStore<Model> where Model.ID: Hashable & Sendable {
    let defaultFileName = "\(String(describing: type)).json"
    return try makeSimpleStore(for: type, fileName: defaultFileName, directory: directory)
}
