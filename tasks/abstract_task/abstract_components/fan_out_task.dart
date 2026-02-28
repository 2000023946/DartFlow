part of '../abstract_task.dart';

class _FanOutTask<C extends WorkflowContext> extends AbstractTaskWrapper<C> {
  final ITaskExecutableCollection<C> _parallelTasks;

  _FanOutTask(ITask<C> previous, this._parallelTasks) : super(previous);

  @override
  Future<void> execute(C context) async {
    // 1. Run the prerequisite (e.g., "Check Bluetooth Permissions")
    await firstTask.execute(context);

    // 2. Parallel Blast (The Fan-Out)
    print("🚀 [FAN_OUT] Prerequisite met. Launching parallel execution...");
    await _parallelTasks.executeAll(context);
  }
}
