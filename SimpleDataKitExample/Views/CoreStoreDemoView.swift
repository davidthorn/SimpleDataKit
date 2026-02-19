//
//  CoreStoreDemoView.swift
//  SimpleDataKitExample
//
//  Created by David Thorn on 19.02.2026.
//

import SwiftUI
import SimpleStore

struct CoreStoreDemoView: View {
    @State private var items: [CoreItem] = []

    private let directory: FileManager.SearchPathDirectory = .documentDirectory
    private let fileName = "core-demo.json"

    private let snippet = """
    let store = try makeSimpleStore(for: CoreItem.self, fileName: \"core-demo.json\")
    try await store.insert(CoreItem(name: \"Example\"))
    let all = try await store.all()
    """

    var body: some View {
        List {
            Section("Actions") {
                Button("Load") {
                    Task { try await loadItems() }
                }
                Button("Insert") {
                    Task { try await insertItem() }
                }
                Button("Upsert") {
                    Task { try await upsertItem() }
                }
                Button("Clear List", role: .destructive) {
                    items.removeAll()
                }
                Button("Delete All", role: .destructive) {
                    Task { try await deleteAll() }
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
        .navigationTitle("Core Store API")
        .task {
            try? await loadItems()
        }
    }

    private func makeStore() throws -> SimpleStore<CoreItem> {
        try makeSimpleStore(for: CoreItem.self, fileName: fileName, directory: directory)
    }

    private func loadItems() async throws {
        let store = try makeStore()
        items = try await store.all()
    }

    private func insertItem() async throws {
        let store = try makeStore()
        let count = try await store.count()
        if Task.isCancelled { return }
        try await store.insert(CoreItem(name: "Core Insert \(count)"))
        items = try await store.all()
    }

    private func upsertItem() async throws {
        let store = try makeStore()
        let count = try await store.count()
        if Task.isCancelled { return }
        try await store.upsert(CoreItem(name: "Core Upsert \(count)"))
        items = try await store.all()
    }

    private func deleteAll() async throws {
        let store = try makeStore()
        try await store.deleteAll()
        items = []
    }
}

#Preview {
    NavigationStack {
        CoreStoreDemoView()
    }
}
