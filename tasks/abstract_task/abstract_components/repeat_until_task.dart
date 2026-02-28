part of '../abstract_task.dart';

class _RepeatUntilTask<C extends WorkflowContext>
    extends AbstractTaskWrapper<C> {
  final bool Function(C) _exitCondition;
  final int _maxAttempts;

  _RepeatUntilTask(ITask<C> task, this._exitCondition, this._maxAttempts)
    : super(task);

  @override
  Future<void> execute(C context) async {
    int attempt = 0;

    // We use firstTask here because it's the 'source' of the loop
    while (!_exitCondition(context) && attempt < _maxAttempts) {
      attempt++;
      print(
        "🔁 [RETRY] Attempt $attempt of $_maxAttempts for ${firstTask.runtimeType}",
      );
      await firstTask.execute(context);
    }
  }
}
