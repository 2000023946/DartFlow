// file: package:mobile/pubSub/framework/broadcaster/broadcaster_certs.dart

/// A secure token required to perform administrative tasks on the Broadcaster.
final class BroadcasterAuthorityCertificate {
  // Private constructor prevents instantiation outside this file.
  BroadcasterAuthorityCertificate._();
}

/// The only class allowed to issue Authority Certificates.
abstract final class BroadcasterCertificateManager {
  /// Issues a certificate to the requester.
  /// In a strict implementation, you can check the 'requester' type.
}
