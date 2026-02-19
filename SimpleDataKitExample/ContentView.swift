//
//  ContentView.swift
//  SimpleDataKitExample
//
//  Created by David Thorn on 19.02.26.
//

import SwiftUI
import SimpleStoreUI
import SimpleStore

struct ContentView: View {
    @SimpleStoreItems(
        StackItem.self,
        directory: .documentDirectory
    ) private var manualItems

    var body: some View {
        TabView {
            listDemoTab
            stackDemoTab
            manualDemoTab
        }
    }

    private var listDemoTab: some View {
        NavigationStack {
            SimpleStoreList(ListItem.self, directory: .documentDirectory) { item in
                Text(item.name)
            }
            .navigationTitle("SimpleStoreList")
            .toolbar {
                ToolbarItem {
                    Button {
                        Task {
                            try await addListItem()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .tabItem {
            Label("List", systemImage: "list.bullet")
        }
    }

    private var stackDemoTab: some View {
        NavigationStack {
            SimpleStoreStack(StackItem.self, directory: .documentDirectory, spacing: 0) { item in
                SimpleStoreStackRow {
                    Text(item.name)
                }
            }
            .navigationTitle("SimpleStoreStack")
            .toolbar {
                ToolbarItem {
                    Button {
                        Task {
                            try await addStackItem()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .tabItem {
            Label("Stack", systemImage: "square.stack.3d.up")
        }
    }

    private var manualDemoTab: some View {
        NavigationStack {
            List(manualItems, id: \.id) { item in
                Text(item.name)
                    .padding(.vertical, 10)
            }
            .navigationTitle("Manual Store + List")
            .toolbar {
                ToolbarItem {
                    Button {
                        Task {
                            try await addManualItem()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .tabItem {
            Label("Manual", systemImage: "square.stack")
        }
    }

    private func addListItem() async throws {
        let count = try await ListItem.count(directory: .documentDirectory)
        if Task.isCancelled {
            return
        }

        let item = ListItem(name: "List Item \(count)")
        if try await item.exists(directory: .documentDirectory) == false {
            if Task.isCancelled {
                return
            }
            try await item.persist(directory: .documentDirectory)
        }
    }

    private func addStackItem() async throws {
        let count = try await StackItem.count(directory: .documentDirectory)
        if Task.isCancelled {
            return
        }

        let item = StackItem(name: "Stack Item \(count)")
        if try await item.exists(directory: .documentDirectory) == false {
            if Task.isCancelled {
                return
            }
            try await item.persist(directory: .documentDirectory)
        }
    }

    private func addManualItem() async throws {
        let store = try await resolveGlobalStore(for: StackItem.self, directory: .documentDirectory)
        let count = try await store.count()
        if Task.isCancelled {
            return
        }

        let item = StackItem(name: "Manual Item \(count)")
        if try await store.exists(id: item.id) == false {
            if Task.isCancelled {
                return
            }
            try await store.insert(item)
        }
    }
}

#Preview {
    ContentView()
}
