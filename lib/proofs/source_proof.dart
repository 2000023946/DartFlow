import 'proof.dart';

/// Proof originating from an external source (UI, API, etc.)
abstract class SourceProof extends Proof {
  SourceProof(Map<String, dynamic> payload, {String? correlationId})
    : super(payload, correlationId: correlationId);
}
