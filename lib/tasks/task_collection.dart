// file: package:mobile/pubSub/framework/tasks/task_collection.dart

import '../dag/workflow_context.dart';
import 'interfaces/i_task.dart';
import 'interfaces/i_task_collection.dart';

class TaskCollection<C extends WorkflowContext> extends ITaskCollection<C> {
  @override
  final List<ITask<C>> tasks;

  /// Creates a simple collection of tasks for branching or parallel execution.
  /// The compiler will now prevent mixing tasks from different context types.
  TaskCollection(this.tasks);
}
