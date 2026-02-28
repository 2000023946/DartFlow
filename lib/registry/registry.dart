// file: framework/registry/registry.dart

import '../event_bus/workflow_result.dart';
import '../orchestrator/i_orchestrator.dart';
import '../proofs/source_proof.dart';
import 'i_registry.dart';

final class Registry implements IRegistry {
  Registry._privateConstructor();
  static final Registry _instance = Registry._privateConstructor();
  factory Registry() => _instance;

  final Map<Type, IOrchestrator> _registry = {};

  @override
  void register<R extends WorkflowResult>(
    Type sourceProofType,
    IOrchestrator<R> orchestrator,
  ) {
    _registry[sourceProofType] = orchestrator;
  }

  @override
  void unregister(Type sourceProofType) {
    _registry.remove(sourceProofType);
  }

  @override
  IOrchestrator<R>? getOrchestrator<R extends WorkflowResult>(
    SourceProof proof,
  ) {
    return _registry[proof.runtimeType] as IOrchestrator<R>?;
  }
}
