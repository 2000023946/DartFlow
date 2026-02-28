// file: package:mobile/pubSub/framework/tasks/i_task_executable_collection.dart

import 'dart:async';

import '../../dag/workflow_context.dart';
import 'i_task_collection.dart';

/// An executable collection that runs tasks in parallel using a shared [C] context.
/// Used for Fan-Out logic where multiple independent domain invariants are met simultaneously.
abstract class ITaskExecutableCollection<C extends WorkflowContext>
    extends ITaskCollection<C> {
  /// High-level trigger for parallel execution.
  Future<void> executeAll(C context) async {
    await performTasks(context);
  }

  /// The raw parallel execution logic.
  /// Every task in the collection gets a reference to the same domain-specific context.
  Future<void> performTasks(C context) async {
    // We use Future.wait to ensure the "Fan-Out" is truly parallel.
    // The generic <C> ensures that all tasks are compatible with the passed context.
    await Future.wait(tasks.map((task) => task.execute(context)));
  }
}
