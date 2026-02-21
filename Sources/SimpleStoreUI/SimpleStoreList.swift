//
//  SimpleStoreList.swift
//  SimpleStoreUI
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
public struct SimpleStoreList<Model: Codable & Identifiable & Sendable & Hashable, RowContent: View>: View where Model.ID: Hashable & Sendable {
    @SimpleStoreItems private var items: [Model]

    private let rowContent: (Model) -> RowContent

    public init(
        _ type: Model.Type,
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
        storeName: String? = nil,
        @ViewBuilder rowContent: @escaping (Model) -> RowContent
    ) {
        self._items = SimpleStoreItems(type, directory: directory, storeName: storeName)
        self.rowContent = rowContent
    }

    public var body: some View {
        List(items) { item in
            rowContent(item)
        }
    }
}

#if DEBUG
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
#Preview {
    SimpleStoreList(SimpleStoreListPreviewItem.self, directory: .cachesDirectory) { item in
        VStack(alignment: .leading) {
            Text(item.title)
            Text(item.id.uuidString)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
#endif

#endif
