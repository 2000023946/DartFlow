// file: framework/event_bus/abstract_event_bus.dart

import 'dart:async';
import 'i_event_bus.dart';
import 'workflow_result.dart';

abstract class AbstractEventBus<R extends WorkflowResult>
    implements IEventBus<R> {
  final StreamController<R> _controller = StreamController<R>.broadcast();

  @override
  void notify(R result) => _controller.add(result);

  @override
  Stream<R> listen() => _controller.stream;

  @override
  void close() => _controller.close();

  @override
  void closeWithError(Object error, StackTrace stackTrace) {
    _controller.addError(error, stackTrace);
    _controller.close();
  }
}
