part of '../abstract_task.dart';

class _SwitchTask<C extends WorkflowContext> extends AbstractTaskWrapper<C> {
  final ITaskCollection<C> _cases;

  _SwitchTask(ITask<C> previous, this._cases) : super(previous);

  @override
  Future<void> execute(C context) async {
    await firstTask.execute(context);

    for (var task in _cases.tasks) {
      if (task.condition(context)) {
        print("✅ [SWITCH] Branching into: ${task.runtimeType}");
        return await task.execute(context);
      }
    }
  }
}
