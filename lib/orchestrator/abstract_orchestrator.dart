// file: framework/orchestrator/abstract_orchestrator.dart

import 'dart:async';
import '../dag/execution_engine.dart';
import '../dag/graph_compiler.dart';
import '../dag/graph_validator.dart';
import '../dag/workflow_context.dart';

import '../event_bus/abstract_event_bus.dart';
import '../event_bus/workflow_result.dart';
import '../proofs/source_proof.dart';
import '../tasks/interfaces/i_task.dart';
import 'i_orchestrator.dart';

abstract class AbstractOrchestrator<
  C extends WorkflowContext<R>,
  R extends WorkflowResult
>
    implements IOrchestrator<R> {
  final ExecutionEngine _engine = ExecutionEngine();
  final ITask<C> _rootTask;

  AbstractOrchestrator(this._rootTask) {
    _initializeAndValidate();
  }

  void _initializeAndValidate() {
    final compiler = GraphCompiler();
    final graph = compiler.compile(_rootTask);
    final validator = GraphValidator();
    validator.validate(graph);
  }

  C createContext(AbstractEventBus<R> bus);
  AbstractEventBus<R> createBus();

  @override
  Stream<R> performTaskFlow(SourceProof proof) {
    final bus = createBus();
    final context = createContext(bus);

    context.protectedSet(proof.runtimeType, proof);

    _engine
        .run<C>(_rootTask, context)
        .then((_) => bus.close())
        .catchError(
          (error, stackTrace) => bus.closeWithError(error, stackTrace),
        );

    return bus.listen();
  }
}
