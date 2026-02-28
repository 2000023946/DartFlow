part of '../abstract_task.dart';

abstract class AbstractTaskWrapper<C extends WorkflowContext>
    extends AbstractTask<C> {
  final ITask<C> firstTask;

  AbstractTaskWrapper(this.firstTask);

  @override
  // 🛡️ THE GLOBAL FIX: Every wrapper now automatically delegates its condition
  bool Function(C) get condition => (context) {
    final canRun = firstTask.condition(context);
    // We keep the print here so you can still spy on the delegation
    print(
      "🔄 [${this.runtimeType}] Delegating condition to ${firstTask.runtimeType}: $canRun",
    );
    return canRun;
  };
}
