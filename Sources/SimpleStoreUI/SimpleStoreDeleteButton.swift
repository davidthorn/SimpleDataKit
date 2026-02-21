//
//  SimpleStoreDeleteButton.swift
//  SimpleStoreUI
//
//  Created by David Thorn on 21.02.2026.
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI
import SimpleStore

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
public struct SimpleStoreDeleteButton<Model: Codable & Identifiable & Sendable & Hashable, Label: View>: View where Model.ID: Hashable & Sendable {
    private let id: Model.ID
    private let directory: FileManager.SearchPathDirectory
    private let storeName: String?
    private let onCompletion: @MainActor @Sendable (Error?) -> Void
    private let label: () -> Label

    public init(
        _ type: Model.Type,
        id: Model.ID,
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
        storeName: String? = nil,
        onCompletion: @escaping @MainActor @Sendable (Error?) -> Void = { _ in },
        @ViewBuilder label: @escaping () -> Label
    ) {
        _ = type
        self.id = id
        self.directory = directory
        self.storeName = storeName
        self.onCompletion = onCompletion
        self.label = label
    }

    public var body: some View {
        Button(role: .destructive) {
            Task {
                if Task.isCancelled {
                    onCompletion(CancellationError())
                    return
                }

                do {
                    let store = try await resolveGlobalStore(for: Model.self, directory: directory, name: storeName)
                    try await store.delete(id: id)
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
    SimpleStoreDeleteButton(
        SimpleStoreListPreviewItem.self,
        id: UUID(),
        directory: .cachesDirectory,
        storeName: "preview-button"
    ) { _ in
    } label: {
        Image(systemName: "trash")
    }
}
#endif

#endif
