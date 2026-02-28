// file: framework/event_bus/i_event_bus.dart

import 'dart:async';

import 'workflow_result.dart';

abstract interface class IEventBus<R extends WorkflowResult> {
  /// Emit a result event into the stream
  void notify(R result);

  /// Returns the stream callers can listen to
  Stream<R> listen();

  /// Close the stream when workflow completes
  void close();

  void closeWithError(Object error, StackTrace stackTrace);
}
