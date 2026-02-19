# SimpleDataKit

`SimpleDataKit` is a Swift package that contains two libraries:

- `SimpleStore`: actor-based, file persistence for `Codable & Identifiable & Sendable & Hashable` models
- `SimpleStoreUI`: optional SwiftUI helpers built on top of `SimpleStore`

Together they provide simple CRUD APIs, live updates via `AsyncStream`, and reusable UI abstractions.

## Why Use SimpleDataKit?

If you are a junior developer, this package gives you:

- A simple way to persist app data without setting up a full database
- Safer concurrency by default (`actor`-based store)
- Predictable behavior with explicit reads/writes
- Live UI updates using streams
- Optional UI abstractions so you can start with less boilerplate

Use `SimpleStore` when you need small-to-medium local persistence (hundreds to low-thousands of records) and you want clarity over framework magic.
Use `SimpleStoreUI` when you also want ready-to-use SwiftUI abstractions that remove repetitive loading and stream wiring.

## Package Products

This package ships two libraries:

- `SimpleStore`: core persistence engine (Foundation only)
- `SimpleStoreUI`: optional SwiftUI abstractions (`@SimpleStoreItems`, `SimpleStoreList`, `SimpleStoreStack`, `SimpleStoreStackRow`)

## Installation (Swift Package Manager)

```swift
.package(url: "https://github.com/davidthorn/SimpleDataKit.git", from: "0.1.0")
```

Core only:

```swift
.product(name: "SimpleStore", package: "SimpleDataKit")
```

Core + UI:

```swift
.product(name: "SimpleStore", package: "SimpleDataKit"),
.product(name: "SimpleStoreUI", package: "SimpleDataKit")
```

## Model Requirements

Your model must conform to:

- `Codable`
- `Identifiable`
- `Sendable`
- `Hashable`

Example:

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

## Quick Start (Core)

### 1. Create a store

```swift
import Foundation
import SimpleStore

let store = try makeSimpleStore(for: Todo.self) // file name derived from type: Todo.json
```

Or explicit file:

```swift
let store = try makeSimpleStore(for: Todo.self, fileName: "todos.json")
```

### 1.1 Choose a directory (important)

You can choose where files are stored using `FileManager.SearchPathDirectory`.

Common options:

- `.applicationSupportDirectory` (recommended default)
- `.cachesDirectory`
- `.documentDirectory`

Best choice for most app data:

- `.applicationSupportDirectory`

Why:

- Intended for app-managed persistent data
- Not user-facing
- Better default for internal store files

When to use others:

- `.cachesDirectory`: re-creatable data you can rebuild (can be purged by system)
- `.documentDirectory`: user-visible/user-managed files

Examples:

```swift
let supportStore = try makeSimpleStore(
    for: Todo.self,
    directory: .applicationSupportDirectory
)

let cacheStore = try makeSimpleStore(
    for: Todo.self,
    directory: .cachesDirectory
)

let documentsStore = try makeSimpleStore(
    for: Todo.self,
    directory: .documentDirectory
)
```

### 2. Insert / Upsert / Update

```swift
let todo = Todo(title: "Buy milk")

try await store.insert(todo)      // create only, throws if ID exists
try await store.upsert(todo)      // create or overwrite by ID
try await store.update(todo)      // update only, throws if ID missing
```

### 3. Read

```swift
let all = try await store.all()
let one = try await store.read(id: todo.id)
let firstDone = try await store.first { $0.done }
```

### 4. Delete

```swift
try await store.delete(id: todo.id)
try await store.delete(ids: [id1, id2, id3])
try await store.deleteAll()
```

## Global Functional API (No Store Variable Needed)

These APIs are useful when you want minimal setup.

```swift
import SimpleStore

try await save(Todo(title: "Write docs"))
let todos = try await loadAll(Todo.self)
let todo = try await load(Todo.self, id: someID)

try await remove(Todo.self, id: someID)
try await removeAll(Todo.self)
```

### Count APIs

```swift
let total = try await count(Todo.self)
let completed = try await count(Todo.self) { $0.done }
```

## Query APIs

Store-level:

```swift
let filtered = try await store.filter { $0.title.contains("milk") }
let hasDone = try await store.contains { $0.done }
let doneCount = try await store.count { $0.done }
```

Global functional queries:

```swift
let filtered = try await query(Todo.self) { $0.title.contains("milk") }
let first = try await loadFirst(Todo.self) { $0.done }
let hasDone = try await contains(Todo.self) { $0.done }
let doneCount = try await count(Todo.self) { $0.done }
```

## Live Updates with AsyncStream

### Store stream

```swift
let updates = await store.stream

Task {
    for await snapshot in updates {
        print("Updated count:", snapshot.count)
    }
}
```

### Global stream

```swift
let updates = try await stream(Todo.self)

Task {
    for await snapshot in updates {
        print("Todos:", snapshot)
    }
}
```

Custom buffering:

```swift
let updates = try await stream(
    Todo.self,
    bufferingPolicy: .bufferingNewest(1)
)
```

## Error Behavior

`SimpleStore` throws `SimpleStore<Model>.StoreError`.

Common cases:

- `.alreadyExists(id:)`
- `.notFound(id:)`
- `.encodingFailed`
- `.decodingFailed`
- `.fileSystemOperationFailed`
- `.unknown(error:)`

Example:

```swift
do {
    let todo = try await store.read(id: id)
    print(todo)
} catch let error as SimpleStore<Todo>.StoreError {
    switch error {
    case .notFound(let id):
        print("Missing ID:", id)
    default:
        print(error)
    }
}
```

## Type Erasure (`AnySimpleStore`)

Use `AnySimpleStore` when you want one concrete type while hiding implementation details.

```swift
let fileStore = try makeSimpleStore(for: Todo.self)
let erased = AnySimpleStore(fileStore)

try await erased.insert(Todo(title: "Type erased"))
let todos = try await erased.all()
```

## SwiftUI (`SimpleStoreUI`)

Import:

```swift
import SimpleStoreUI
```

### `@SimpleStoreItems`

Auto-loads and auto-subscribes to store updates.

```swift
struct TodosView: View {
    @SimpleStoreItems(Todo.self) private var todos

    var body: some View {
        List(todos) { todo in
            Text(todo.title)
        }
    }
}
```

### `SimpleStoreList`

List-based view that handles loading/streaming for you.

```swift
SimpleStoreList(Todo.self) { todo in
    Text(todo.title)
}
```

### `SimpleStoreStack`

ScrollView + LazyVStack variant.

```swift
SimpleStoreStack(Todo.self, spacing: 0) { todo in
    SimpleStoreStackRow {
        Text(todo.title)
    }
}
```

### `SimpleStoreStackRow`

List-like row styling helper for stack layouts.

```swift
SimpleStoreStackRow(showsSeparator: true) {
    VStack(alignment: .leading) {
        Text(todo.title)
        Text(todo.id.uuidString).font(.caption)
    }
}
```

## Best Practices

- Prefer `upsert` when syncing external data.
- Use explicit `insert` / `update` when you want strict write behavior.
- Use one model type per store file.
- Keep model structs small and focused.
- For UI, prefer `SimpleStoreUI` wrappers to reduce boilerplate.

## When Not to Use SimpleStore

Consider a heavier solution if you need:

- Complex relational data modeling
- Advanced indexing/query planners
- Very large datasets
- Multi-process shared database features

## API Overview

### Core store

- `insert`, `upsert`, `update`
- `all`, `read`, `first`, `filter`
- `contains(id:)`, `contains(where:)`
- `count()`, `count(where:)`
- `delete(id:)`, `delete(ids:)`, `deleteAll`, `replaceAll`
- `stream`, `makeStream(bufferingPolicy:)`

### Global functions

- `save`, `load`, `loadAll`, `loadFirst`
- `remove`, `removeAll`
- `query`
- `contains`, `count`
- `stream`

## License

Add your license here (for example MIT).
