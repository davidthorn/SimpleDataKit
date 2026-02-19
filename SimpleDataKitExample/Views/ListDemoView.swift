//
//  ListDemoView.swift
//  SimpleDataKitExample
//
//  Created by David Thorn on 19.02.2026.
//

import SwiftUI
import SimpleStore
import SimpleStoreUI

struct ListDemoView: View {
    private let directory: FileManager.SearchPathDirectory = .documentDirectory

    private let snippet = """
    SimpleStoreList(ListItem.self, directory: .documentDirectory) { item in
        Text(item.name)
    }
    """

    var body: some View {
        SimpleStoreList(ListItem.self, directory: directory) { item in
            Text(item.name)
        }
        .navigationTitle("SimpleStoreList")
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
        let total = try await ListItem.count(directory: directory)
        if Task.isCancelled { return }
        try await ListItem(name: "List \(total)").persist(directory: directory)
    }
}

#Preview {
    NavigationStack {
        ListDemoView()
    }
}
