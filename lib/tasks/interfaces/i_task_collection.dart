// file: package:mobile/pubSub/framework/tasks/i_task_collection.dart

import 'dart:collection';

import '../../dag/workflow_context.dart';
import 'i_task.dart';

/// A collection of tasks that handle different branches of a workflow.
/// [C] ensures all tasks in the collection consume the same context type.
abstract class ITaskCollection<C extends WorkflowContext>
    with IterableMixin<ITask<C>> {
  /// The list of tasks to be executed or selected from.
  List<ITask<C>> get tasks;

  @override
  Iterator<ITask<C>> get iterator => tasks.iterator;

  @override
  int get length => tasks.length;

  bool get isEmpty => tasks.isEmpty;
}
