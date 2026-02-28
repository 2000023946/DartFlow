abstract class Proof {
  final String correlationId;
  final Map<String, dynamic> payload;

  Proof(this.payload, {String? correlationId})
    : correlationId = correlationId ?? const Uuid().v4();
}

class Uuid {
  const Uuid();

  v4() {}
}
