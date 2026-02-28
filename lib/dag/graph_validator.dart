import 'task_graph.dart';
import 'graph_node.dart';

class GraphValidator {
  void validate(TaskGraph graph) {
    _ensureSingleSource(graph);
    _ensureAtLeastOneSink(graph);
    _ensureNoCycles(graph);
  }

  void _ensureSingleSource(TaskGraph graph) {
    // A source has no incoming edges.
    final sources = graph.nodes.where((n) => n.incoming.isEmpty).toList();
    if (sources.length != 1) {
      throw Exception(
        'DAG Error: Flow must have exactly one entry point. Found ${sources.length}.',
      );
    }
  }

  void _ensureAtLeastOneSink(TaskGraph graph) {
    // A sink has no outgoing edges.
    final sinks = graph.nodes.where((n) => n.outgoing.isEmpty).toList();
    if (sinks.isEmpty) {
      throw Exception(
        'DAG Error: Flow must have at least one terminal (sink) task.',
      );
    }
  }

  void _ensureNoCycles(TaskGraph graph) {
    final visited = <GraphNode>{};
    final recursionStack = <GraphNode>{};

    void check(GraphNode node) {
      visited.add(node);
      recursionStack.add(node);

      for (final neighbor in node.outgoing) {
        if (recursionStack.contains(neighbor)) {
          throw Exception(
            'DAG Error: Cycle detected! Task "${neighbor.task.runtimeType}" loops back.',
          );
        }
        if (!visited.contains(neighbor)) {
          check(neighbor);
        }
      }
      recursionStack.remove(node);
    }

    check(graph.source);
  }
}
