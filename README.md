# 🌊 DartFlow

### The Industrial-Grade Orchestration Engine for Dart & Flutter.

**DartFlow** is a strictly typed, event-driven orchestration framework. It allows you to wire immutable events to **Directed Acyclic Graphs (DAGs)**, executing complex business logic with mathematical certainty and streaming typed results back in real-time.

---

## 🚀 Why DartFlow?

In modern app development, state management handles the *UI*. **DartFlow handles the *Process*.** If you've ever struggled with "spaghetti services" where logic is scattered across nested `if/else` blocks and uncoordinated `async` calls, DartFlow is the solution. It turns your business requirements into a visible, verifiable, and testable graph.

### Key Features

* **Write-Once Context**: A `WorkflowContext` prevents "silent overwrites." Once a fact is established in a run, it is immutable.
* **DAG Validation**: The framework validates your task graph at **runtime startup**. If there are cycles or disconnected nodes, it fails immediately—never in production.
* **Total Isolation**: Each `publish` call creates a unique "Run." No shared state, no side effects between concurrent workflows.
* **Type Safety**: End-to-end generics ensure that your `Stream<Result>` is fully typed. No `dynamic` or `Object` casting.

---

## 🛠 Core Concepts

### 1. The Trigger: `SourceProof`

Everything starts with a "Proof"—an immutable data object that justifies the start of a workflow.

```dart
class UploadFileProof extends SourceProof {
  final String filePath;
  final String destination;
  UploadFileProof(this.filePath, this.destination);
}

```

### 2. The Workspace: `WorkflowContext`

The context is a shared "fact bag" for the workflow. It uses symbols or types as keys.

```dart
class UploadContext extends WorkflowContext<UploadResult> {
  UploadContext(super.bus);

  // Helper for typed access
  File get file => protectedGet<File>(#file_handle);
  void setFile(File f) => protectedSet(#file_handle, f);
}

```

### 3. The Logic: `Tasks`

A task is a single unit of work. It reads from the context, performs logic, and notifies the bus.

```dart
class ResizeImageTask extends AbstractTask<UploadContext> {
  @override
  Future<void> execute(UploadContext context) async {
    // Logic here...
    context.bus.notify(UploadResult()..status = 'Resizing complete');
  }
}

```

---

## 🏗 Composition Primitives

Build complex logic using a fluent API. DartFlow supports:

| Primitive | Logic |
| --- | --- |
| **`.then(Task)`** | **Sequential**: Run B after A. |
| **`.thenSwitch([Tasks])`** | **Conditional**: Run the first task whose `condition` returns true. |
| **`.fanOut([Tasks])`** | **Parallel**: Run multiple tasks simultaneously. |
| **`.onFailure(Task)`** | **Resilience**: Define a recovery path if a task throws. |
| **`.repeatUntil(Task)`** | **Retry**: Loop logic until a specific state is achieved. |

### The "Power" Example

```dart
CheckAuthTask()
  .then(InitializeUploadTask())
  .thenSwitch([
    SmallFileUploadTask(), // If < 5MB
    MultipartUploadTask(), // If > 5MB
  ])
  .fanOut([
    UpdateLocalDbTask(),
    NotifyAnalyticsTask(),
  ])
  .onFailure(CleanupTempFilesTask());

```

---

## 📡 The Broadcaster (The Entry Point)

Registration is gated by a `BroadcasterAuthorityCertificate` to ensure only authorized modules can define workflows.

```dart
final broadcaster = Broadcaster(BroadcasterAuthorityCertificate());

// Registering a workflow
broadcaster.register<UploadFileProof, UploadResult>(UploadOrchestrator());

// Executing a workflow
final stream = broadcaster.publish<UploadResult>(UploadFileProof('/path/to/img.png', 'cloud/storage'));

stream.listen((update) {
  print("Current Progress: ${update.percent}%");
});

```

---

## 🔍 The Lifecycle

1. **Event In**: `SourceProof` is published.
2. **Context Creation**: An isolated context and event bus are instantiated.
3. **Graph Compilation**: The DAG is optimized and sorted.
4. **Execution**: Tasks run in topological order. Parallel tasks (`fanOut`) run concurrently.
5. **Stream Out**: Tasks push `WorkflowResult` objects to the caller's stream.
6. **Cleanup**: The bus closes automatically when the "sink" tasks finish.

---

## 📦 Installation

Add DartFlow to your `pubspec.yaml`:

```yaml
dependencies:
  dartflow: ^1.0.0

```

---

## ⚖️ License

Licensed under the **MIT License**.

---
