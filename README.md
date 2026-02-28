# 🌊 DartFlow

### A strictly typed, event-driven orchestration framework for Dart & Flutter.

**DartFlow** isn't just another state management library. It is a robust **orchestration engine** designed to handle complex, asynchronous business logic by wiring immutable events to **Directed Acyclic Graphs (DAGs)**.

While tools like Bloc or Provider manage *how the UI looks*, DartFlow manages *how your logic flows*—ensuring every step of a process is ordered, conditional, and parallelized with industrial-grade safety.

---

## 🚀 The Core Philosophy

In traditional app development, complex logic (like a multi-step Bluetooth connection or a multi-stage checkout) often becomes "spaghetti code" hidden inside services. **DartFlow** turns this logic into a visible, verifiable graph.

### The 4 Pillars of DartFlow

1. **Immutability**: Data entering the system (**SourceProof**) and facts shared between tasks (**WorkflowContext**) are strictly controlled.
2. **Isolation**: Every execution run is its own "universe" with a dedicated event bus. No leaked state.
3. **Graph Safety**: Your workflow is a DAG. Cycles and disconnected nodes are caught at **startup**, not in production.
4. **Type Integrity**: From the triggering event to the final stream output, types are preserved. No `dynamic` casting required.

---

## 🛠 Core Components

### 1. SourceProof (The Trigger)

An immutable "envelope" containing the data required to start a workflow.

```dart
class UserLoginProof extends SourceProof {
  final String email;
  final String password;
  UserLoginProof(this.email, this.password);
}

```

### 2. WorkflowContext (The Fact Bag)

A **write-once** storage container shared across tasks. If Task A sets a user ID, Task B can read it, but Task C cannot overwrite it. This prevents race conditions.

```dart
class AuthContext extends WorkflowContext<AuthResult> {
  AuthContext(super.bus);

  // Strictly typed getters/setters
  String? get token => has(#token) ? protectedGet<String>(#token) : null;
  void setToken(String t) => protectedSet(#token, t);
}

```

### 3. Tasks (The Units of Work)

Tasks are where your logic lives. They can be synchronous or asynchronous. They emit results to the UI via the `context.bus`.

```dart
class AuthenticateTask extends AbstractTask<AuthContext> {
  @override
  Future<void> execute(AuthContext context) async {
    final token = await api.login(context.proof.email, context.proof.password);
    context.setToken(token); // Store for future tasks
    context.bus.notify(AuthResult()..status = 'Authenticated'); // Notify UI
  }
}

```

---

## 🏗 Composing the Graph (Fluent API)

DartFlow provides seven powerful primitives to describe even the most complex enterprise workflows.

| Primitive | Behavior |
| --- | --- |
| **`.then()`** | **Sequential**: Run Task B only after Task A succeeds. |
| **`.thenSwitch()`** | **Branching**: Run the first task that meets a logical condition. |
| **`.fanOut()`** | **Parallel**: Launch multiple tasks at once (e.g., Fetch Profile + Fetch Settings). |
| **`.fanIn()`** | **Barrier**: Wait for all parallel tasks to finish before moving on. |
| **`.onFailure()`** | **Error Handling**: Define a specific fallback task if a node fails. |
| **`.repeatUntil()`** | **Resilience**: Automatically retry logic until a condition is met. |

### Example Composition:

```dart
CheckNetworkTask()
  .then(LoginTask())
  .fanOut([
    FetchUserDataTask(),
    SyncLocalCacheTask(),
  ])
  .fanIn(FinalizeSessionTask())
  .onFailure(ShowErrorTask());

```

---

## 📡 The Broadcaster

The `Broadcaster` is the entry point. It uses a **Certificate-Gated Registration** system, meaning only authorized modules can register orchestrators, preventing "hijacking" of your business logic.

```dart
// 1. Setup
final broadcaster = Broadcaster(BroadcasterAuthorityCertificate());
broadcaster.register<UserLoginProof, AuthResult>(AuthOrchestrator());

// 2. Execute & Listen
broadcaster
  .publish<AuthResult>(UserLoginProof('dev@dartflow.io', 'password123'))
  .listen((result) {
    print("Update from workflow: ${result.status}");
  });

```

---

## 🔍 Execution Lifecycle

1. **Publish**: A `SourceProof` is sent to the `Broadcaster`.
2. **Lookup**: The Registry finds the `Orchestrator` mapped to that proof.
3. **Isolation**: A new `WorkflowContext` and `EventBus` are created for this specific run.
4. **Validation**: The `ExecutionEngine` verifies the DAG hasn't been corrupted.
5. **Traversal**: Tasks execute in topological order.
6. **Streaming**: Results are streamed back to the caller in real-time.
7. **Teardown**: Once the "Sink" nodes of the graph complete, the bus closes automatically.

---

## 📁 Project Structure

```text
framework/
├── broadcaster/     # Entry point & Authority gating
├── dag/             # The "Brain": Compiler, Validator, & Engine
├── event_bus/       # Real-time communication layer
├── orchestrator/    # Workflow definitions
├── proofs/          # Input event definitions
├── registry/        # Proof-to-Orchestrator mapping
└── tasks/           # Composition primitives & Task base classes

```

---

## 💎 Why choose DartFlow?

* **Auditability**: Because the context is write-once, you can log exactly what "facts" were known at every step of the execution.
* **Testability**: Tasks are small, decoupled, and take a typed context, making unit testing trivial.
* **Safety**: Stop chasing `null` errors and race conditions. The DAG ensures things happen in the order you intended.
* **Performance**: Pure Dart logic. No heavy dependencies. Lightweight enough for the smallest apps, powerful enough for the largest.

---
