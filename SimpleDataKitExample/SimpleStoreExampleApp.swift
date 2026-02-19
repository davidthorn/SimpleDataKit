//
//  SimpleDataKitExampleApp.swift
//  SimpleDataKitExample
//
//  Created by David Thorn on 19.02.26.
//

import SwiftUI
import SimpleStore

nonisolated struct ListItem: Codable, Identifiable, Hashable, Persistable {
    let id: UUID
    let name: String
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

nonisolated struct StackItem: Codable, Identifiable, Hashable, Persistable {
    let id: UUID
    let name: String
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

@main
struct SimpleDataKitExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
