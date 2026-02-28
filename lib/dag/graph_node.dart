import '../tasks/interfaces/i_task.dart';

class GraphNode {
  final ITask task;

  final List<GraphNode> outgoing = [];
  final List<GraphNode> incoming = [];

  GraphNode(this.task);

  void connect(GraphNode next) {
    outgoing.add(next);
    next.incoming.add(this);
  }
}
