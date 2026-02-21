# SimpleDataKit

`SimpleDataKit` helps you ship local-data Swift apps quickly.

It provides two libraries:
- `SimpleStore`: actor-based persistence for `Codable & Identifiable & Sendable & Hashable` models
- `SimpleStoreUI`: SwiftUI helpers for loading, streaming, and common CRUD actions

If you are new to architecture, this README is written so you can still build a working app first.

## Project Philosophy

SimpleDataKit is designed to help junior developers learn by shipping.

The intended learning path is:
1. Get a proof-of-concept working quickly with minimal friction.
2. Understand persistence and UI streaming in small, local examples.
3. Gradually introduce clearer architecture boundaries as the app grows (separate UI code, state handling, and persistence responsibilities).

Learning advanced patterns like protocol-heavy designs, dependency injection, and deeper abstractions is valuable, but it takes experience and context.
Early on, the higher priority is delivering bug-free, working apps on time.

The global function APIs exist to accelerate early development and learning. They are intentionally simple, and they are not the end-state architecture for larger apps.

As projects mature, move toward explicit store usage, typed action clients, and clearer separation of concerns.

## Start Here First

If this is your first time using SimpleDataKit, follow this order:
1. Install package.
2. Create one model (`Todo`).
3. Use `@SimpleStoreActions` in one view.
4. Add one insert action and one delete action.
5. Confirm data appears and updates in the list.

Do this before adding extra abstraction layers.

## Install (Xcode, Step by Step)

Use Swift Package Manager in Xcode.

1. Open your app project in Xcode.
2. Click `File` -> `Add Package Dependencies...`
3. Paste this URL: `https://github.com/davidthorn/SimpleDataKit.git`
4. Choose version rule: `Up to Next Major` from `0.1.0`
5. Click `Add Package`
6. Select products:
- `SimpleStore` (required)
- `SimpleStoreUI` (optional, for SwiftUI helpers)

Then import in code where needed:

```swift
import SimpleStore
import SimpleStoreUI
```

If you prefer `Package.swift`, use:

```swift
.package(url: "https://github.com/davidthorn/SimpleDataKit.git", from: "0.1.0")
```

Products:

```swift
.product(name: "SimpleStore", package: "SimpleDataKit")
.product(name: "SimpleStoreUI", package: "SimpleDataKit")
```

## Model

Your model must conform to:
- `Codable`
- `Identifiable`
- `Sendable`
- `Hashable`

Why each one is required:

- `Codable`: lets `SimpleStore` save your model to disk (encode) and read it back (decode).
- `Identifiable`: gives every model a stable `id` so updates, deletes, and reads can target one specific entity.
- `Sendable`: keeps concurrency safe when values move across async/actor boundaries.
- `Hashable`: allows efficient identity/set operations and predictable comparisons in store internals and UI helpers.

Tip for beginners:
- Use `UUID` for `id`.
- Start with simple value types (`struct` with `String`, `Int`, `Bool`, `Date`, etc.).
- Add custom types later once your basic flow works.

```swift
import Foundation

public struct Todo: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public var title: String
    public var done: Bool

    public init(id: UUID = UUID(), title: String, done: Bool = false) {
        self.id = id
        self.title = title
        self.done = done
    }
}
```

## Choose Your API (Simple Rule)

Use this decision rule:
- Use `@SimpleStoreActions` for most new SwiftUI screens (best beginner default).
- Use `@SimpleStoreItems` when you only need read + stream behavior.
- Use core `SimpleStore` directly when you want full explicit control.
- Use global functions (`save`, `loadAll`, `delete`, etc.) for very quick POC code.

## Core Store (Direct)

```swift
import SimpleStore

let store = try makeSimpleStore(
    for: Todo.self,
    directory: .applicationSupportDirectory
)

try await store.insert(Todo(title: "Buy milk"))
try await store.upsert(Todo(title: "Write docs"))

let all = try await store.all()
let firstDone = try await store.first { $0.done }

try await store.delete(id: all[0].id)
try await store.deleteAll()
```

## Global Functions (Default Global Store)

Use these when you want minimal setup and default store behavior.
This is great for first POC iterations, but move to `@SimpleStoreActions` or explicit store usage as features grow.

```swift
import SimpleStore

try await save(Todo(title: "Ship app"))
let todos = try await loadAll(Todo.self)
let countAll = try await count(Todo.self)

let hasDone = try await contains(Todo.self) { $0.done }
let doneCount = try await count(Todo.self) { $0.done }

let one = try await load(Todo.self, id: todos[0].id)
try await delete(Todo.self, id: one.id)
try await deleteAll(Todo.self)
```

## Named Stores (Explicit)

Named stores give you isolated data spaces for the same model type.

Use named stores when you want to keep one workflow's data completely separate from another workflow's data.

This is especially useful for:

- SwiftUI previews:
  Use a preview-only name (for example `"preview"`) so preview data never mixes with real app data.
- Tests:
  Use a test-specific name per test/suite to avoid cross-test contamination and flaky results.
- Sandboxed flows:
  Try risky or temporary behavior without touching your main persisted data.
- Feature experiments:
  Run alternate flows (for example onboarding variants) against isolated datasets.

Default behavior reminder:
- Global helper functions like `save`, `loadAll`, `delete`, `deleteAll` use the default global store.
- Named stores are an explicit path, so you must resolve/register them directly.

Use explicit resolution/registration for named stores:

```swift
import SimpleStore

let named = try await resolveGlobalStore(
    for: Todo.self,
    directory: .cachesDirectory,
    name: "preview"
)

try await named.insert(Todo(title: "Preview item"))
let previewTodos = try await named.all()
```

Practical pattern:
1. Pick a stable name for the context (`"preview"`, `"tests"`, `"sandbox"`, etc.).
2. Resolve the named store once in that context.
3. Perform all reads/writes through that resolved store.
4. Keep default global helpers for your normal app flow.

Optional explicit registration:

```swift
let memoryStore = InMemorySimpleStore<Todo>()
await registerGlobalStore(memoryStore, for: Todo.self, directory: .cachesDirectory, name: "preview")
```

## Persistable

```swift
import SimpleStore

public struct Todo: Persistable {
    public let id: UUID
    public var title: String
    public var done: Bool

    public init(id: UUID = UUID(), title: String, done: Bool = false) {
        self.id = id
        self.title = title
        self.done = done
    }
}

let todo = Todo(title: "Call API")
try await todo.persist()
let exists = try await todo.exists()
try await todo.delete()
try await Todo.deleteAll()
```

## SwiftUI Quick Setup

### Complete beginner example (single view, working CRUD flow)

```swift
import SwiftUI
import SimpleStoreUI

struct TodosView: View {
    @SimpleStoreActions(Todo.self, directory: .applicationSupportDirectory)
    private var actions

    var body: some View {
        NavigationStack {
            List($actions) { todo in
                HStack {
                    Text(todo.title)
                    Spacer()
                    actions.deleteAction(id: todo.id) { error in
                        if let error {
                            print("Delete failed:", error)
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .toolbar {
                actions.insertAction {
                    Todo(title: "Todo \(Date())")
                } label: {
                    Image(systemName: "plus")
                }
            }
            .navigationTitle("Todos")
        }
    }
}
```

What this gives you immediately:
- Data is persisted.
- List updates automatically.
- Insert and delete work with minimal boilerplate.

### 1. Read + stream items automatically

This is one of the core productivity features of `SimpleStoreUI`.

When you declare `@SimpleStoreItems`, the store is automatically resolved for that model and directory, initial data is loaded, and live streaming updates are wired for you.
You do not need to manually create a store, manually call `loadAll`, or manually manage an `AsyncStream` task.

In short: declare once, and the persistence + streaming plumbing is handled internally.

```swift
import SwiftUI
import SimpleStoreUI

struct TodosView: View {
    @SimpleStoreItems(Todo.self) private var todos

    var body: some View {
        List(todos) { todo in
            Text(todo.title)
        }
    }
}
```

### 2. Unified actions + streamed items with one wrapper

```swift
import SwiftUI
import SimpleStoreUI

struct TodosView: View {
    @SimpleStoreActions(Todo.self, directory: .cachesDirectory, storeName: "preview")
    private var actions

    var body: some View {
        VStack {
            List($actions) { todo in
                Text(todo.title)
            }

            actions.insertAction {
                Todo(title: "Added")
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}
```

`@SimpleStoreActions` gives you:
- `actions`: action API (`insert`, `upsert`, `delete`, `deleteAll`, `query`, `count`, etc.)
- `$actions`: current streamed `[Model]`

Why this matters:
- You can build and validate your view quickly with real persistence behavior.
- You can keep early code local to the view while your feature is still evolving.

As your app grows, you can move to a more layered structure:
1. View
2. ViewModel
3. Service layer
4. Data store

`actions` helps you ship the first working version now, then extract business logic into ViewModel/service layers later without rewriting your whole feature from scratch.

## Reusable UI Components

- `SimpleStoreList(Model.self, storeName: ...)`
- `SimpleStoreStack(Model.self, storeName: ...)`
- `SimpleStoreStackRow { ... }`
- `SimpleStoreInsertButton(...)`
- `SimpleStoreDeleteButton(...)`

Example delete button:

```swift
actions.deleteAction(id: todo.id) { error in
    if let error {
        print("Delete failed:", error)
    }
} label: {
    Image(systemName: "trash")
}
```

## Directory Guidance

- Use `.applicationSupportDirectory` for normal app-managed persistent data
- Use `.cachesDirectory` for replaceable/preview/test data
- Use `.documentDirectory` only when user-visible file behavior is intended

## Common Beginner Mistakes

1. Changing model `id` accidentally.
Always keep `id` stable once created, otherwise updates/deletes may not target the expected row.

2. Using default global store for preview/test data.
Use named stores for preview/tests so you do not pollute normal app data.

3. Adding too much architecture too early.
Ship a clean working screen first, then extract layers when duplication or complexity appears.

## Notes

- `remove` / `removeAll` aliases exist for compatibility; use `delete` / `deleteAll` in new code.
- `SimpleStore` is ideal for straightforward local persistence and UI-driven apps.

## Contributing

Contributions are welcome, especially improvements that make the package clearer for junior developers.

When contributing:
1. Prefer clarity over cleverness in naming and API design.
2. Keep examples practical and focused on building real apps quickly.
3. Preserve the teaching path: simple first, architecture depth second.
4. Keep public APIs consistent (`delete` naming, explicit store behavior, predictable defaults).
5. Add or update tests for behavioral changes.

Before opening a PR:
1. Run `swift test`.
2. Update README examples when public API usage changes.
3. Keep docs focused on current usage, not historical migration notes.
