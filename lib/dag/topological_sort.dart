import 'task_graph.dart';
import 'graph_node.dart';

class TopologicalSort {
  List<GraphNode> sort(TaskGraph graph) {
    final inDegree = <GraphNode, int>{};

    for (var node in graph.nodes) {
      inDegree[node] = node.incoming.length;
    }

    final queue = <GraphNode>[...graph.nodes.where((n) => inDegree[n] == 0)];

    final result = <GraphNode>[];

    while (queue.isNotEmpty) {
      final node = queue.removeLast();
      result.add(node);

      for (final neighbor in node.outgoing) {
        inDegree[neighbor] = inDegree[neighbor]! - 1;
        if (inDegree[neighbor] == 0) {
          queue.add(neighbor);
        }
      }
    }

    if (result.length != graph.nodes.length) {
      throw Exception('Graph contains a cycle');
    }

    return result;
  }
}
