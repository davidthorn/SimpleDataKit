//
//  SimpleStoreItems.swift
//  SimpleStore
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

@propertyWrapper
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
@MainActor
public struct SimpleStoreItems<Model: Codable & Identifiable & Sendable & Hashable>: @preconcurrency DynamicProperty where Model.ID: Hashable & Sendable {
    @StateObject private var loader: SimpleStoreItemsLoader<Model>

    public init(
        _ type: Model.Type,
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory
    ) {
        _loader = StateObject(wrappedValue: SimpleStoreItemsLoader(type: type, directory: directory))
    }

    public var wrappedValue: [Model] {
        loader.items
    }

    public var projectedValue: SimpleStoreItemsLoader<Model> {
        loader
    }

    public mutating func update() {
        _loader.update()
        loader.startIfNeeded()
    }
}
#endif
