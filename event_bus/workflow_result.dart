// file: framework/event_bus/workflow_result.dart

abstract class WorkflowResult {
  final Map<dynamic, dynamic> _store = {};

  void set(dynamic key, dynamic value) => _store[key] = value;

  T? get<T>(dynamic key) => _store[key] as T?;
}
