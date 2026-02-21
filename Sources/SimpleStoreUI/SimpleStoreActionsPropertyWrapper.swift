//
//  SimpleStoreActionsPropertyWrapper.swift
//  SimpleStoreUI
//
//  Created by David Thorn on 21.02.2026.
//

import Foundation

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

@propertyWrapper
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
@MainActor
public struct SimpleStoreActions<Model: Codable & Identifiable & Sendable & Hashable>: @preconcurrency DynamicProperty where Model.ID: Hashable & Sendable {
    @StateObject private var store: SimpleStoreActionsClient<Model>

    public init(
        _ type: Model.Type,
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
        storeName: String? = nil
    ) {
        _store = StateObject(
            wrappedValue: SimpleStoreActionsClient(
                type: type,
                directory: directory,
                storeName: storeName
            )
        )
    }

    public var wrappedValue: SimpleStoreActionsClient<Model> {
        store
    }

    public var projectedValue: [Model] {
        store.items
    }

    public mutating func update() {
        _store.update()
        store.startIfNeeded()
    }
}
#endif
