// file: framework/registry/i_registry.dart

import '../event_bus/workflow_result.dart';
import '../orchestrator/i_orchestrator.dart';
import '../proofs/source_proof.dart';

abstract class IRegistry {
  void register<R extends WorkflowResult>(
    Type sourceProofType,
    IOrchestrator<R> orchestrator,
  );

  void unregister(Type sourceProofType);

  IOrchestrator<R>? getOrchestrator<R extends WorkflowResult>(
    SourceProof proof,
  );
}
