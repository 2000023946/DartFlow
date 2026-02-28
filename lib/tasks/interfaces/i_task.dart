// file: package:mobile/pubSub/framework/tasks/i_task.dart

import 'dart:async';

import '../../dag/workflow_context.dart';
import 'i_task_collection.dart';
import 'i_task_executable_collection.dart';

/// Base interface for domain-agnostic, chainable tasks.
/// [C] allows users to provide their own specialized WorkflowContext.
abstract class ITask<C extends WorkflowContext> {
  /// Execute the task's logic using the domain-specific context.
  Future<void> execute(C context);

  /// Sequentially chain another task.
  /// The next task must accept the same context type.
  ITask<C> then(ITask<C> next);

  /// Conditional branching within the same context type.
  ITask<C> thenSwitch(ITaskCollection<C> tasks);

  /// Fallback task if the execution of this specific node throws an exception.
  ITask<C> onFailure(ITask<C> fallback);

  /// Repeat the current task until a condition in the context [C] is met.
  ITask<C> repeatUntil(bool Function(C) condition, {required int maxAttempts});

  /// Fan-out: run multiple independent tasks in parallel using context [C].
  ITask<C> fanOut(ITaskExecutableCollection<C> tasks);

  /// Fan-in: return to a single flow after parallel execution.
  ITask<C> fanIn(ITask<C> next);

  /// Optional condition to determine if this node should be skipped.
  bool Function(C) get condition;
}
