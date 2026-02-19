//
//  StartHereView.swift
//  SimpleDataKitExample
//
//  Created by David Thorn on 19.02.2026.
//

import SwiftUI

struct StartHereView: View {
    private let snippet = """
    import SimpleStore

    struct Todo: Persistable {
        let id: UUID
        let name: String
    }

    let todo = Todo(id: UUID(), name: \"Buy milk\")
    try await todo.persist()
    let all = try await Todo.loadAll()
    """

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("SimpleDataKit")
                        .font(.title.bold())

                    Text("Choose an example from the Examples tab. Each screen focuses on one API style with copy-ready snippets.")
                        .foregroundColor(.secondary)

                    Text("Quick Start")
                        .font(.headline)

                    Text(snippet)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("Start Here")
        }
    }
}

#Preview {
    StartHereView()
}
