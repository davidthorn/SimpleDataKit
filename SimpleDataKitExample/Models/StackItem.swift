//
//  StackItem.swift
//  SimpleDataKitExample
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation
import SimpleStore

public struct StackItem: Codable, Identifiable, Sendable, Hashable, Persistable {
    public let id: UUID
    public let name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
