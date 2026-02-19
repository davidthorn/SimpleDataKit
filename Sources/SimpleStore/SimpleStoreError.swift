//
//  SimpleStoreError.swift
//  SimpleStore
//
//  Created by David Thorn on 18.02.2026.
//

import Foundation

/// Errors thrown by `SimpleStoreProtocol` conforming stores.
public enum SimpleStoreError: Error {
    /// The requested model does not exist.
    case notFound

    /// The model already exists and cannot be inserted again.
    case alreadyExists

    /// The persisted data could not be encoded.
    case encodingFailed

    /// The persisted data could not be decoded.
    case decodingFailed

    /// The file system operation failed.
    case fileSystemOperationFailed

    /// An uncategorized error occurred.
    /// - Parameter error: The underlying error.
    case unknown(error: Error)
}
