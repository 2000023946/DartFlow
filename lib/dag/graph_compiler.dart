// file: package:mobile/pubSub/framework/dag/graph_compiler.dart

import '../tasks/abstract_task/abstract_task.dart';
import '../tasks/interfaces/i_task.dart';
import 'graph_node.dart';
import 'task_graph.dart';

class GraphCompiler {
  /// Compiles a chain of ITask into a formal TaskGraph for the ExecutionEngine.
  TaskGraph compile(ITask root) {
    final visited = <ITask, GraphNode>{};

    GraphNode build(ITask task) {
      // 1. Memoization: Ensure we don't duplicate nodes or loop forever
      if (visited.containsKey(task)) {
        return visited[task]!;
      }

      final node = GraphNode(task);
      visited[task] = node;

      // 2. We use the 'children' getter we defined in our AbstractTask wrappers
      // This is how the compiler "sees" through a .then() or a .thenSwitch()
      if (task is AbstractTask) {
        for (final childTask in task.children) {
          final childNode = build(childTask);
          node.connect(childNode);
        }
      }

      return node;
    }

    final sourceNode = build(root);
    return TaskGraph(sourceNode, visited.values.toSet());
  }
}
