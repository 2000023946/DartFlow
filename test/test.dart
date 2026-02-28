import 'dart:async';

// ==========================================
// FRAMEWORK (trimmed for test)
// ==========================================

abstract class WorkflowResult {
  final Map<dynamic, dynamic> _store = {};
  void set(dynamic key, dynamic value) => _store[key] = value;
  T? get<T>(dynamic key) => _store[key] as T?;
}

abstract class WorkflowContext<R extends WorkflowResult> {
  final AbstractEventBus<R> bus;
  final Map<dynamic, dynamic> _registry = {};

  WorkflowContext(this.bus);

  void protectedSet(dynamic key, dynamic value) {
    if (_registry.containsKey(key)) {
      throw StateError("Immutable Violation: Fact [$key] already set.");
    }
    _registry[key] = value;
  }

  T protectedGet<T>(dynamic key) {
    final value = _registry[key];
    if (value == null) throw StateError("Invariant Violation: [$key] missing.");
    return value as T;
  }

  bool has(dynamic key) => _registry.containsKey(key);
}

abstract class AbstractEventBus<R extends WorkflowResult> {
  final StreamController<R> _controller = StreamController<R>.broadcast();

  void notify(R result) => _controller.add(result);
  Stream<R> listen() => _controller.stream;
  void close() => _controller.close();
  void closeWithError(Object error, StackTrace stackTrace) {
    _controller.addError(error, stackTrace);
    _controller.close();
  }
}

abstract class ITask<C extends WorkflowContext> {
  Future<void> execute(C context);
  bool Function(C) get condition =>
      (_) => true;
  ITask<C> then(ITask<C> next) => _ChainedTask(this, next);
  ITask<C> thenSwitch(List<ITask<C>> cases) => _SwitchTask(this, cases);
  ITask<C> onFailure(ITask<C> fallback) => _FailureTask(this, fallback);
}

class _ChainedTask<C extends WorkflowContext> extends ITask<C> {
  final ITask<C> _first, _second;
  _ChainedTask(this._first, this._second);

  @override
  Future<void> execute(C context) async {
    await _first.execute(context);
    await _second.execute(context);
  }
}

class _SwitchTask<C extends WorkflowContext> extends ITask<C> {
  final ITask<C> _previous;
  final List<ITask<C>> _cases;
  _SwitchTask(this._previous, this._cases);

  @override
  Future<void> execute(C context) async {
    await _previous.execute(context);
    for (final task in _cases) {
      if (task.condition(context)) return await task.execute(context);
    }
  }
}

class _FailureTask<C extends WorkflowContext> extends ITask<C> {
  final ITask<C> _previous, _fallback;
  _FailureTask(this._previous, this._fallback);

  @override
  Future<void> execute(C context) async {
    try {
      await _previous.execute(context);
    } catch (e) {
      await _fallback.execute(context);
    }
  }
}

abstract class AbstractOrchestrator<
  C extends WorkflowContext<R>,
  R extends WorkflowResult
> {
  final ITask<C> _rootTask;
  AbstractOrchestrator(this._rootTask);

  C createContext(AbstractEventBus<R> bus);
  AbstractEventBus<R> createBus();

  Stream<R> performTaskFlow(SourceProof proof) {
    final bus = createBus();
    final context = createContext(bus);
    context.protectedSet(proof.runtimeType, proof);

    _rootTask
        .execute(context)
        .then((_) => bus.close())
        .catchError((e, s) => bus.closeWithError(e, s));

    return bus.listen();
  }
}

abstract class SourceProof {}

// ==========================================
// DOMAIN — Simple "Connect Device" workflow
// ==========================================

// --- Source Proof (the event) ---
class ConnectDeviceProof extends SourceProof {
  final String deviceId;
  ConnectDeviceProof(this.deviceId);
}

// --- Workflow Result ---
class BleResult extends WorkflowResult {
  String? get status => get<String>(#status);
  set status(String? v) => set(#status, v);

  String? get deviceId => get<String>(#deviceId);
  set deviceId(String? v) => set(#deviceId, v);

  String? get error => get<String>(#error);
  set error(String? v) => set(#error, v);
}

// --- Event Bus ---
class BleEventBus extends AbstractEventBus<BleResult> {}

// --- Context ---
class BleContext extends WorkflowContext<BleResult> {
  BleContext(BleEventBus bus) : super(bus);

  ConnectDeviceProof get proof =>
      protectedGet<ConnectDeviceProof>(ConnectDeviceProof);

  bool get isConnected =>
      has(#connected) ? protectedGet<bool>(#connected) : false;

  void setConnected(bool v) => protectedSet(#connected, v);
}

// --- Tasks ---
class CheckCacheTask extends ITask<BleContext> {
  @override
  Future<void> execute(BleContext context) async {
    // simulate cache miss
    context.setConnected(false);
  }
}

class ConnectTask extends ITask<BleContext> {
  @override
  bool Function(BleContext) get condition =>
      (ctx) => !ctx.isConnected;

  @override
  Future<void> execute(BleContext context) async {
    final result = BleResult()
      ..status = 'connected'
      ..deviceId = context.proof.deviceId;
    context.bus.notify(result);
  }
}

class AlreadyConnectedTask extends ITask<BleContext> {
  @override
  bool Function(BleContext) get condition =>
      (ctx) => ctx.isConnected;

  @override
  Future<void> execute(BleContext context) async {
    final result = BleResult()..status = 'already_connected';
    context.bus.notify(result);
  }
}

class BuggyTask extends ITask<BleContext> {
  @override
  Future<void> execute(BleContext context) async {
    throw Exception('Hardware timeout');
  }
}

class FallbackTask extends ITask<BleContext> {
  @override
  Future<void> execute(BleContext context) async {
    final result = BleResult()
      ..status = 'fallback'
      ..error = 'Hardware timeout';
    context.bus.notify(result);
  }
}

// --- Orchestrator ---
class BleOrchestrator extends AbstractOrchestrator<BleContext, BleResult> {
  BleOrchestrator()
    : super(
        CheckCacheTask()
            .thenSwitch([AlreadyConnectedTask(), ConnectTask()])
            .then(BuggyTask().onFailure(FallbackTask())),
      );

  @override
  BleEventBus createBus() => BleEventBus();

  @override
  BleContext createContext(AbstractEventBus<BleResult> bus) =>
      BleContext(bus as BleEventBus);
}

// ==========================================
// TESTS
// ==========================================

int _passed = 0;
int _failed = 0;

Future<void> test(String name, Future<void> Function() body) async {
  try {
    await body();
    print('  ✅ $name');
    _passed++;
  } catch (e) {
    print('  ❌ $name: $e');
    _failed++;
  }
}

void expect(dynamic actual, dynamic expected, String message) {
  if (actual != expected) {
    throw Exception(
      '$message\n     expected: $expected\n     got:      $actual',
    );
  }
}

Future<void> main() async {
  print('\n🧪 kneems_framework — end to end tests\n');

  final orchestrator = BleOrchestrator();

  // --- Test 1: connects successfully and emits result ---
  await test('emits connected status for new device', () async {
    final results = <BleResult>[];
    final stream = orchestrator.performTaskFlow(
      ConnectDeviceProof('device-123'),
    );
    await stream.listen(results.add).asFuture();

    final connected = results.firstWhere((r) => r.status == 'connected');
    expect(connected.deviceId, 'device-123', 'deviceId should match proof');
  });

  // --- Test 2: fallback fires when buggy task throws ---
  await test('fallback task emits on hardware failure', () async {
    final results = <BleResult>[];
    final stream = orchestrator.performTaskFlow(
      ConnectDeviceProof('device-456'),
    );
    await stream.listen(results.add).asFuture();

    final fallback = results.firstWhere((r) => r.status == 'fallback');
    expect(
      fallback.error,
      'Hardware timeout',
      'error message should propagate',
    );
  });

  // --- Test 3: stream closes after workflow completes ---
  await test('stream closes cleanly after workflow', () async {
    final stream = orchestrator.performTaskFlow(
      ConnectDeviceProof('device-789'),
    );
    final results = await stream.toList();
    expect(results.isNotEmpty, true, 'should have emitted at least one result');
  });

  // --- Test 4: context write-once throws on duplicate set ---
  await test('context throws on duplicate protectedSet', () async {
    final bus = BleEventBus();
    final ctx = BleContext(bus);
    ctx.protectedSet(#myKey, 'first');

    try {
      ctx.protectedSet(#myKey, 'second');
      throw Exception('should have thrown');
    } on StateError catch (e) {
      expect(
        e.message.contains('Immutable Violation'),
        true,
        'should throw immutable violation',
      );
    }
  });

  // --- Test 5: context throws when key missing ---
  await test('context throws on missing key', () async {
    final bus = BleEventBus();
    final ctx = BleContext(bus);

    try {
      ctx.protectedGet<String>(#missing);
      throw Exception('should have thrown');
    } on StateError catch (e) {
      expect(
        e.message.contains('Invariant Violation'),
        true,
        'should throw invariant violation',
      );
    }
  });

  // --- Summary ---
  print('\n${'─' * 40}');
  print('  passed: $_passed  failed: $_failed');
  print('${'─' * 40}\n');

  if (_failed > 0) throw Exception('$_failed test(s) failed');
}
