//
//  StackDemoView.swift
//  SimpleDataKitExample
//
//  Created by David Thorn on 19.02.2026.
//

import SwiftUI
import SimpleStore
import SimpleStoreUI

struct StackDemoView: View {
    private let directory: FileManager.SearchPathDirectory = .documentDirectory

    private let snippet = """
    SimpleStoreStack(StackItem.self, directory: .documentDirectory, spacing: 0) { item in
        SimpleStoreStackRow {
            Text(item.name)
        }
    }
    """

    var body: some View {
        SimpleStoreStack(StackItem.self, directory: directory, spacing: 0) { item in
            SimpleStoreStackRow {
                Text(item.name)
            }
        }
        .navigationTitle("SimpleStoreStack")
        .toolbar {
            ToolbarItem {
                Button {
                    Task { try await addItem() }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Text(snippet)
                .font(.system(.caption, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial)
        }
    }

    private func addItem() async throws {
        let total = try await StackItem.count(directory: directory)
        if Task.isCancelled { return }
        try await StackItem(name: "Stack \(total)").persist(directory: directory)
    }
}

#Preview {
    NavigationStack {
        StackDemoView()
    }
}
