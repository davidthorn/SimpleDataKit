//
//  PersistableDemoView.swift
//  SimpleDataKitExample
//
//  Created by David Thorn on 19.02.2026.
//

import SwiftUI
import SimpleStore

struct PersistableDemoView: View {
    @State private var items: [PersistableItem] = []

    private let directory: FileManager.SearchPathDirectory = .documentDirectory

    private let snippet = """
    let item = PersistableItem(name: \"Example\")
    try await item.persist()
    let all = try await PersistableItem.loadAll()
    let hasAny = try await PersistableItem.contains { !$0.name.isEmpty }
    """

    var body: some View {
        List {
            Section("Actions") {
                Button("Load") {
                    Task { try await loadItems() }
                }
                Button("Persist") {
                    Task { try await addItem() }
                }
                Button("Clear All", role: .destructive) {
                    Task { try await clearAll() }
                }
            }

            Section("Items") {
                if items.isEmpty {
                    Text("No items yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(items) { item in
                        Text(item.name)
                    }
                }
            }

            Section("Code") {
                Text(snippet)
                    .font(.system(.footnote, design: .monospaced))
            }
        }
        .navigationTitle("Persistable API")
        .task {
            try? await loadItems()
        }
    }

    private func loadItems() async throws {
        items = try await PersistableItem.loadAll(directory: directory)
    }

    private func addItem() async throws {
        let total = try await PersistableItem.count(directory: directory)
        if Task.isCancelled { return }
        let item = PersistableItem(name: "Persistable \(total)")
        try await item.persist(directory: directory)
        items = try await PersistableItem.loadAll(directory: directory)
    }

    private func clearAll() async throws {
        try await PersistableItem.removeAll(directory: directory)
        items = []
    }
}

#Preview {
    NavigationStack {
        PersistableDemoView()
    }
}
