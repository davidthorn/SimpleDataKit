//
//  SimpleStoreTestEntity.swift
//  SimpleStore
//
//  Created by David Thorn on 19.02.2026.
//

import Foundation

public struct SimpleStoreTestEntity: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public let name: String
    public let value: Double

    public init(id: UUID, name: String, value: Double) {
        self.id = id
        self.name = name
        self.value = value
    }
}
