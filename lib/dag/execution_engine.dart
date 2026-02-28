// file: package:mobile/pubSub/framework/dag/execution_engine.dart

import '../tasks/interfaces/i_task.dart';
import 'graph_compiler.dart';
import 'graph_validator.dart';
import 'workflow_context.dart';

class ExecutionEngine {
  final GraphCompiler _compiler = GraphCompiler();
  final GraphValidator _validator = GraphValidator();

  /// Runs the workflow using a specific context type [C].
  Future<void> run<C extends WorkflowContext>(
    ITask<C> rootTask,
    C context,
  ) async {
    // 1. Compile the "Blueprint" into a Graph
    // This allows us to see the structure of your .then().thenSwitch() calls
    final graph = _compiler.compile(rootTask);

    // 2. Validate the Topology
    // We check for cycles and disconnected nodes here
    _validator.validate(graph);

    print('🚀 [EXECUTION] DAG Verified: ${graph.nodes.length} nodes.');

    try {
      // 3. Trigger the Recursive Execution
      // Because we use wrappers (_ChainedTask, _SwitchTask),
      // calling execute(context) on the root triggers the entire chain.
      await rootTask.execute(context);

      print('✅ [EXECUTION] Workflow completed successfully.');
    } catch (e) {
      print('❌ [EXECUTION] Critical failure in workflow: $e');
      rethrow;
    }
  }
}
