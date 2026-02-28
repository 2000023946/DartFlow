// file: framework/orchestrator/i_orchestrator.dart

import 'dart:async';
import '../event_bus/workflow_result.dart';
import '../proofs/source_proof.dart';

abstract interface class IOrchestrator<R extends WorkflowResult> {
  Stream<R> performTaskFlow(SourceProof proof);
}
