// file: package:mobile/pubSub/framework/tasks/abstract_task.dart

import 'dart:async';

import '../../dag/workflow_context.dart';
import '../interfaces/i_task.dart';
import '../interfaces/i_task_collection.dart';
import '../interfaces/i_task_executable_collection.dart';

part 'abstract_components/abstract_task_wrapper.dart';
part 'abstract_components/switch_task.dart';
part 'abstract_components/chain_task.dart';
part 'abstract_components/repeat_until_task.dart';
part 'abstract_components/failure_task.dart';
part 'abstract_components/fan_out_task.dart';

abstract class AbstractTask<C extends WorkflowContext> implements ITask<C> {
  List<ITask<C>> get children => [];
  @override
  bool Function(C) get condition => (C context) {
    // 🕵️ THE SMOKING GUN: This is what's running instead of your Policy Task
    print(
      "⚠️ [FRAMEWORK_WARNING] Running DEFAULT AbstractTask condition (returns false) for: ${this.runtimeType}",
    );
    return false;
  };

  @override
  Future<void> execute(C context);

  @override
  ITask<C> then(ITask<C> next) => _ChainedTask<C>(this, next);

  @override
  ITask<C> onFailure(ITask<C> fallback) => _FailureTask<C>(this, fallback);

  @override
  ITask<C> repeatUntil(
    bool Function(C) condition, {
    required int maxAttempts,
  }) => _RepeatUntilTask<C>(this, condition, maxAttempts);

  @override
  ITask<C> fanOut(ITaskExecutableCollection<C> tasks) =>
      _FanOutTask<C>(this, tasks);

  @override
  ITask<C> thenSwitch(ITaskCollection<C> tasks) => _SwitchTask<C>(this, tasks);

  // Note: fanIn becomes simpler because the context already has the parallel data
  @override
  ITask<C> fanIn(ITask<C> next) => _ChainedTask<C>(this, next);
}

// file: package:mobile/pubSub/framework/tasks/_repeat_until_task.dart

// file: package:mobile/pubSub/framework/tasks/_failure_task.dart

// file: package:mobile/pubSub/framework/tasks/_fan_out_task.dart

// file: package:mobile/pubSub/framework/tasks/_fan_out_task.dart
