// file: framework/broadcaster/broadcaster.dart

import 'dart:async';
import '../event_bus/workflow_result.dart';
import '../orchestrator/i_orchestrator.dart';
import '../proofs/source_proof.dart';
import '../registry/i_registry.dart';
import '../registry/registry.dart';
import 'broadcaster_certs.dart';
import 'i_broadcaster.dart';

final class Broadcaster implements IBroadcaster {
  static final Broadcaster _instance = Broadcaster._privateConstructor();
  final IRegistry _registry = Registry();

  Broadcaster._privateConstructor();
  factory Broadcaster(BroadcasterAuthorityCertificate certificate) => _instance;

  @override
  void register<T extends SourceProof, R extends WorkflowResult>(
    IOrchestrator<R> orchestrator,
  ) {
    _registry.register(T, orchestrator);
  }

  @override
  Stream<R> publish<R extends WorkflowResult>(SourceProof proof) {
    final orchestrator = _registry.getOrchestrator<R>(proof);
    if (orchestrator == null) {
      throw Exception(
        'Security Error: No orchestrator for ${proof.runtimeType}.',
      );
    }
    return orchestrator.performTaskFlow(proof);
  }
}
