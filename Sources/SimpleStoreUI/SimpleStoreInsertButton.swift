//
//  SimpleStoreInsertButton.swift
//  SimpleStoreUI
//
//  Created by David Thorn on 21.02.2026.
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI
import SimpleStore

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
public struct SimpleStoreInsertButton<Model: Codable & Identifiable & Sendable & Hashable, Label: View>: View where Model.ID: Hashable & Sendable {
    private let directory: FileManager.SearchPathDirectory
    private let storeName: String?
    private let makeModel: @Sendable () -> Model
    private let onCompletion: @MainActor @Sendable (Error?) -> Void
    private let label: () -> Label
    
    public init(
        _ type: Model.Type,
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
        storeName: String? = nil,
        makeModel: @escaping @Sendable () -> Model,
        onCompletion: @escaping @MainActor @Sendable (Error?) -> Void = { _ in },
        @ViewBuilder label: @escaping () -> Label
    ) {
        _ = type
        self.directory = directory
        self.storeName = storeName
        self.makeModel = makeModel
        self.onCompletion = onCompletion
        self.label = label
    }
    
    public var body: some View {
        Button {
            Task {
                if Task.isCancelled {
                    onCompletion(CancellationError())
                    return
                }
                
                do {
                    let model = makeModel()
                    let store = try await resolveGlobalStore(for: Model.self, directory: directory, name: storeName)
                    try await store.insert(model)
                    if Task.isCancelled {
                        onCompletion(CancellationError())
                        return
                    }
                    onCompletion(nil)
                } catch {
                    onCompletion(error)
                }
            }
        } label: {
            label()
        }
    }
}

#if DEBUG
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
#Preview {
    SimpleStoreInsertButton(SimpleStoreListPreviewItem.self, directory: .cachesDirectory, storeName: "preview-button") {
        SimpleStoreListPreviewItem(title: "Inserted")
    } onCompletion: { _ in
    } label: {
        Image(systemName: "plus")
    }
}
#endif

#endif
