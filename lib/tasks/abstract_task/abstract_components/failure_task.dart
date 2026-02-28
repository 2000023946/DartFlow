part of '../abstract_task.dart';

class _FailureTask<C extends WorkflowContext> extends AbstractTaskWrapper<C> {
  final ITask<C> fallback;

  _FailureTask(ITask<C> previous, this.fallback) : super(previous);

  @override
  Future<void> execute(C context) async {
    try {
      await firstTask.execute(context);
    } catch (e, stack) {
      print("🚨 [ORCHESTRATION_RESCUE] Primary task failed: $e");
      context.protectedSet("last_error", e);
      context.protectedSet("last_stacktrace", stack);
      await fallback.execute(context);
    }
  }
}
