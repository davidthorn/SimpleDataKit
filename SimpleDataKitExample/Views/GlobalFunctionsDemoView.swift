//
//  GlobalFunctionsDemoView.swift
//  SimpleDataKitExample
//
//  Created by David Thorn on 19.02.2026.
//

import SwiftUI
import SimpleStore

struct GlobalFunctionsDemoView: View {
    @State private var items: [GlobalItem] = []

    private let directory: FileManager.SearchPathDirectory = .documentDirectory

    private let snippet = """
    try await save(GlobalItem(name: \"Example\"))
    let all = try await loadAll(GlobalItem.self)
    let total = try await count(GlobalItem.self)
    """

    var body: some View {
        List {
            Section("Actions") {
                Button("Load") {
                    Task { try await loadItems() }
                }
                Button("Save") {
                    Task { try await saveItem() }
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
        .navigationTitle("Global Functions")
        .task {
            try? await loadItems()
        }
    }

    private func loadItems() async throws {
        items = try await loadAll(GlobalItem.self, directory: directory)
    }

    private func saveItem() async throws {
        let total = try await count(GlobalItem.self, directory: directory)
        if Task.isCancelled { return }
        try await save(GlobalItem(name: "Global Save \(total)"), directory: directory)
        items = try await loadAll(GlobalItem.self, directory: directory)
    }

    private func clearAll() async throws {
        try await removeAll(GlobalItem.self, directory: directory)
        items = []
    }
}

#Preview {
    NavigationStack {
        GlobalFunctionsDemoView()
    }
}
