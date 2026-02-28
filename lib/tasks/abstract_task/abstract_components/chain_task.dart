part of '../abstract_task.dart';

class _ChainedTask<C extends WorkflowContext> extends AbstractTaskWrapper<C> {
  final ITask<C> second;

  _ChainedTask(ITask<C> first, this.second) : super(first);

  @override
  Future<void> execute(C context) async {
    await firstTask.execute(context);
    await second.execute(context);
  }
}
