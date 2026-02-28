import '../event_bus/abstract_event_bus.dart';
import '../event_bus/workflow_result.dart';

abstract class WorkflowContext<R extends WorkflowResult> {
  final AbstractEventBus<R> bus;
  final Map<dynamic, dynamic> _registry = {};

  WorkflowContext(this.bus);

  void protectedSet(dynamic key, dynamic value) {
    if (_registry.containsKey(key)) {
      throw StateError(
        "Immutable Violation: Fact [$key] is already set in this context history.",
      );
    }
    _registry[key] = value;
  }

  T protectedGet<T>(dynamic key) {
    final value = _registry[key];
    if (value == null) {
      throw StateError("Invariant Violation: Fact [$key] is missing.");
    }
    return value as T;
  }

  bool has(dynamic key) => _registry.containsKey(key);
}
