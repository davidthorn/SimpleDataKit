//
//  SimpleStoreStack.swift
//  SimpleStoreUI
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
public struct SimpleStoreStack<Model: Codable & Identifiable & Sendable & Hashable, RowContent: View>: View where Model.ID: Hashable & Sendable {
    @SimpleStoreItems private var items: [Model]

    private let alignment: HorizontalAlignment
    private let spacing: CGFloat?
    private let rowContent: (Model) -> RowContent

    public init(
        _ type: Model.Type,
        directory: FileManager.SearchPathDirectory = .applicationSupportDirectory,
        alignment: HorizontalAlignment = .leading,
        spacing: CGFloat? = nil,
        @ViewBuilder rowContent: @escaping (Model) -> RowContent
    ) {
        self._items = SimpleStoreItems(type, directory: directory)
        self.alignment = alignment
        self.spacing = spacing
        self.rowContent = rowContent
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: alignment, spacing: spacing) {
                ForEach(items) { item in
                    rowContent(item)
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
#Preview {
    SimpleStoreStack(SimpleStoreListPreviewItem.self, directory: .cachesDirectory) { item in
        VStack(alignment: .leading) {
            Text(item.title)
            Text(item.id.uuidString)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    .padding()
}
#endif

#endif
