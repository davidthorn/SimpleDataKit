//
//  StoreFactory.swift
//  SimpleStore
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation

/// Creates `SimpleStore` instances with shared file-system configuration.
public struct StoreFactory {
    private let directoryURL: URL
    
    /// Creates a factory rooted at a directory URL.
    /// - Parameters:
    ///   - directoryURL: The directory where store files are created.
    public init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }
    
    /// Creates a factory rooted in a standard search-path directory.
    /// - Parameters:
    ///   - directory: The system search-path directory to use as a base.
    public init(
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
    ) throws {
        let fileManager = FileManager.default
        let baseURL = try fileManager.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: true)
        self.init(directoryURL: baseURL)
    }
    
    /// Creates a `SimpleStore` for a given model type and file name.
    /// - Parameters:
    ///   - type: The model type.
    ///   - fileName: The store file name.
    /// - Returns: A configured `SimpleStore`.
    public func makeStore<Model: Codable & Identifiable & Sendable & Hashable>(
        for type: Model.Type,
        fileName: String
    ) -> SimpleStore<Model> where Model.ID: Hashable & Sendable {
        let fileURL = directoryURL.appendingPathComponent(fileName)
        return SimpleStore<Model>(fileURL: fileURL)
    }
}
