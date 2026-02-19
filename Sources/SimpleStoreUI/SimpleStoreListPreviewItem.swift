//
//  SimpleStoreListPreviewItem.swift
//  SimpleStoreUI
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation

#if DEBUG
public struct SimpleStoreListPreviewItem: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public let title: String

    public init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
}
#endif
