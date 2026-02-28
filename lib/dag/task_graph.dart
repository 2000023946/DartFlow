import 'graph_node.dart';

class TaskGraph {
  final GraphNode source;
  final Set<GraphNode> nodes;

  TaskGraph(this.source, this.nodes);
}
