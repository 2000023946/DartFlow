// file: framework/broadcaster/i_broadcaster.dart

import 'dart:async';
import '../event_bus/workflow_result.dart';
import '../orchestrator/i_orchestrator.dart';
import '../proofs/source_proof.dart';

abstract interface class IBroadcaster {
  void register<T extends SourceProof, R extends WorkflowResult>(
    IOrchestrator<R> orchestrator,
  );

  Stream<R> publish<R extends WorkflowResult>(SourceProof proof);
}
