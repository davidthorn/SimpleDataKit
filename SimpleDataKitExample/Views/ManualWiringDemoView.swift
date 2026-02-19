//
//  ManualWiringDemoView.swift
//  SimpleDataKitExample
//
//  Created by David Thorn on 19.02.2026.
//

import SwiftUI
import SimpleStore

struct ManualWiringDemoView: View {
    @State private var items: [ManualItem] = []

    private let directory: FileManager.SearchPathDirectory = .documentDirectory

    private let snippet = """
    let store = try await resolveGlobalStore(for: ManualItem.self, directory: .documentDirectory)
    try await store.insert(ManualItem(name: \"Manual\"))
    let all = try await store.all()
    """

    var body: some View {
        List {
            Section("Actions") {
                Button("Load") {
                    Task { try await loadItems() }
                }
                Button("Insert via Store") {
                    Task { try await insertItem() }
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
        .navigationTitle("Manual Store Wiring")
        .task {
            try? await loadItems()
        }
    }

    private func loadItems() async throws {
        let store = try await resolveGlobalStore(for: ManualItem.self, directory: directory)
        items = try await store.all()
    }

    private func insertItem() async throws {
        let store = try await resolveGlobalStore(for: ManualItem.self, directory: directory)
        let total = try await store.count()
        if Task.isCancelled { return }

        let item = ManualItem(name: "Manual \(total)")
        if try await store.exists(id: item.id) == false {
            if Task.isCancelled { return }
            try await store.insert(item)
        }

        items = try await store.all()
    }

    private func clearAll() async throws {
        let store = try await resolveGlobalStore(for: ManualItem.self, directory: directory)
        try await store.deleteAll()
        items = []
    }
}

#Preview {
    NavigationStack {
        ManualWiringDemoView()
    }
}
