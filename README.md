# kneems_framework

A typed, event-driven orchestration framework for Dart and Flutter. Wire immutable events to DAG-based workflows, get typed results back as streams.

---

## What It Does

Most state management in Flutter handles *state*. This framework handles *orchestration* — the ordered, conditional, parallel execution of business logic in response to events.

You define:
- A **SourceProof** — the event that triggers a workflow
- A **WorkflowContext** — the typed fact bag shared across tasks
- **Tasks** — units of work that read from and write to the context
- An **Orchestrator** — wires the tasks into a DAG, validated at startup
- A **WorkflowResult** — typed output emitted back to the caller as a stream

You get back a `Stream<R>` — a live, typed feed of results as the workflow executes.

---

## Core Concepts

### SourceProof

An immutable event that triggers a workflow. No logic, no side effects — just data.

```dart
class ConnectDeviceProof extends SourceProof {
  final String deviceId;
  ConnectDeviceProof(this.deviceId);
}
```

### WorkflowContext

A write-once fact bag. Each orchestration run gets its own isolated context. Attempting to overwrite a fact throws immediately — immutability is enforced at runtime.

```dart
class BleContext extends WorkflowContext<BleResult> {
  BleContext(BleEventBus bus) : super(bus);

  ConnectDeviceProof get proof =>
      protectedGet<ConnectDeviceProof>(ConnectDeviceProof);

  BleDevice? get device =>
      has(#device) ? protectedGet<BleDevice>(#device) : null;

  void setDevice(BleDevice d) => protectedSet(#device, d);
}
```

Facts are stored by key. Typed getters/setters live on your concrete context. The base class enforces write-once semantics — no silent overwrites.

### WorkflowResult

A hashmap-backed result type users extend with typed getters. Tasks emit results into the stream during execution.

```dart
class BleResult extends WorkflowResult {
  String? get status => get<String>(#status);
  set status(String? v) => set(#status, v);

  BleDevice? get device => get<BleDevice>(#device);
  set device(BleDevice? v) => set(#device, v);
}
```

### AbstractEventBus

One bus per workflow run, created by the orchestrator and injected into the context. Tasks emit results via `context.bus.notify(result)`. The bus exposes a broadcast stream and closes cleanly when the workflow completes or errors.

```dart
class BleEventBus extends AbstractEventBus<BleResult> {}
```

### Tasks

Tasks are the units of work. They receive the typed context, do their logic, optionally emit a result, and return `void`. They compose via a fluent API.

```dart
class ConnectTask extends AbstractTask<BleContext> {
  @override
  bool Function(BleContext) get condition => (ctx) => !ctx.isConnected;

  @override
  Future<void> execute(BleContext context) async {
    final device = await _hardware.connect(context.proof.deviceId);
    context.setDevice(device);
    context.bus.notify(BleResult()
      ..status = 'connected'
      ..device = device);
  }
}
```

### Task Composition Primitives

Seven primitives cover every workflow shape:

| Primitive | Description |
|---|---|
| `.then(task)` | Sequential — run task after this one |
| `.thenSwitch([...tasks])` | Exclusive branch — first task whose condition is true runs |
| `.fanOut(tasks)` | Parallel — run multiple tasks simultaneously |
| `.fanIn(task)` | Rejoin after parallel execution |
| `.onFailure(task)` | Fallback — runs if this task throws |
| `.repeatUntil(condition, max)` | Retry loop until condition met or max attempts reached |

Compose them to describe any DAG:

```dart
CheckCacheTask()
  .thenSwitch([AlreadyConnectedTask(), ConnectTask()])
  .then(NegotiateMtuTask()
    .onFailure(MtuFallbackTask()))
  .fanOut(tasks([DiscoverServicesTask(), LogConnectionTask()]))
```

### Orchestrator

The orchestrator owns the task DAG, validates it at startup, and executes it per event. It is the only place that creates the context and bus — ensuring they are always properly paired.

```dart
class BleOrchestrator extends AbstractOrchestrator<BleContext, BleResult> {
  BleOrchestrator()
      : super(
          CheckCacheTask()
            .thenSwitch([AlreadyConnectedTask(), ConnectTask()])
            .then(NegotiateMtuTask().onFailure(MtuFallbackTask())),
        );

  @override
  BleEventBus createBus() => BleEventBus();

  @override
  BleContext createContext(AbstractEventBus<BleResult> bus) =>
      BleContext(bus as BleEventBus);
}
```

The DAG is compiled and validated once at construction time. If your graph has cycles, disconnected nodes, or structural violations — the app crashes immediately on startup, not in production.

### Broadcaster

The singleton event bus. Requires a `BroadcasterAuthorityCertificate` to register orchestrators — preventing arbitrary code from hijacking workflows. Publishing is open to anyone.

```dart
// Registration (authorized module only)
final broadcaster = Broadcaster(BroadcasterAuthorityCertificate());
broadcaster.register<ConnectDeviceProof, BleResult>(BleOrchestrator());

// Publishing (anyone)
final stream = broadcaster.publish<BleResult>(ConnectDeviceProof('device-123'));
stream.listen((result) => print(result.status));
```

---

## Full Example

```dart
// 1. Define your event
class RunWorkflowProof extends SourceProof {
  final String input;
  RunWorkflowProof(this.input);
}

// 2. Define your result
class MyResult extends WorkflowResult {
  String? get output => get<String>(#output);
  set output(String? v) => set(#output, v);
}

// 3. Define your bus
class MyEventBus extends AbstractEventBus<MyResult> {}

// 4. Define your context
class MyContext extends WorkflowContext<MyResult> {
  MyContext(MyEventBus bus) : super(bus);

  RunWorkflowProof get proof =>
      protectedGet<RunWorkflowProof>(RunWorkflowProof);
}

// 5. Define your tasks
class DoWorkTask extends AbstractTask<MyContext> {
  @override
  Future<void> execute(MyContext context) async {
    final result = MyResult()..output = 'processed: ${context.proof.input}';
    context.bus.notify(result);
  }
}

// 6. Define your orchestrator
class MyOrchestrator extends AbstractOrchestrator<MyContext, MyResult> {
  MyOrchestrator() : super(DoWorkTask());

  @override
  MyEventBus createBus() => MyEventBus();

  @override
  MyContext createContext(AbstractEventBus<MyResult> bus) =>
      MyContext(bus as MyEventBus);
}

// 7. Wire it up and run
void main() {
  final broadcaster = Broadcaster(BroadcasterAuthorityCertificate());
  broadcaster.register<RunWorkflowProof, MyResult>(MyOrchestrator());

  broadcaster
    .publish<MyResult>(RunWorkflowProof('hello'))
    .listen((result) => print(result.output)); // processed: hello
}
```

---

## Execution Flow

```
broadcaster.publish(SourceProof)
  → Registry looks up orchestrator by proof type
    → Orchestrator creates EventBus + Context for this run
      → SourceProof seeded into context
        → ExecutionEngine validates and runs the DAG
          → Tasks execute, emit results via context.bus.notify()
            → Stream<R> delivered to caller
              → Bus closes when DAG completes or errors
```

Each call to `publish` is a fully isolated run — its own context, its own bus, its own stream. No shared state between runs.

---

## DAG Validation

The `GraphValidator` checks your task graph at orchestrator construction time:

- No cycles
- No disconnected nodes
- All nodes reachable from root

Validation failures throw immediately. You will never ship a broken workflow topology.

---

## Project Structure

```
framework/
├── broadcaster/       # Singleton event bus + cert-gated registration
├── dag/               # Graph compiler, validator, topological sort, execution engine
├── event_bus/         # AbstractEventBus, IEventBus, WorkflowResult
├── orchestrator/      # AbstractOrchestrator, IOrchestrator
├── proofs/            # SourceProof base
├── registry/          # IRegistry, Registry — proof type → orchestrator mapping
└── tasks/
    ├── abstract_task/           # AbstractTask + internal composition wrappers
    └── interfaces/              # ITask, ITaskCollection, ITaskExecutableCollection
```

---

## Design Decisions

**Write-once context** — facts cannot be overwritten once set. This makes task execution order explicit and auditable. If a task assumes a fact exists, it either finds it or throws — no silent defaults.

**Per-run isolation** — each `publish` call creates a fresh context and bus. There is no shared mutable state between concurrent workflow executions.

**Startup validation** — the DAG is validated when the orchestrator is constructed, not when it first runs. Invalid topology is a programming error, not a runtime condition.

**Cert-gated registration** — only code holding a `BroadcasterAuthorityCertificate` can register orchestrators. This prevents accidental or malicious workflow hijacking.

**Generic typing end-to-end** — `C extends WorkflowContext<R>` and `R extends WorkflowResult` flow from orchestrator through context through bus through stream. The caller's `Stream<R>` is fully typed with no casts.

---

## Requirements

- Dart SDK >= 3.0
- Flutter (optional — framework is pure Dart)

---

## License

MIT
