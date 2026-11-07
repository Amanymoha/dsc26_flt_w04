/// What happened at one stop.
enum OutcomeStatus { delivered, failed }

/// Why a delivery failed. Sent to the server as the enum name,
/// e.g. "customerNotHome".
enum FailureReason { customerNotHome, refused, wrongAddress, ranOutOfTime, other }

/// One delivery outcome recorded by a courier.
///
/// The general constructor accepts any combination so that invalid input can
/// reach `Outbox.record`, which validates it. Use the named constructors in
/// app code.
final class DeliveryOutcome {
  const DeliveryOutcome({
    required this.parcelId,
    required this.status,
    this.reason,
    this.codCollectedPiasters = 0,
    required this.recordedAt,
  });

  /// Delivered, with the cash collected (in piasters: EGP 450 = 45000).
  const DeliveryOutcome.delivered({
    required String parcelId,
    required int codCollectedPiasters,
    required DateTime recordedAt,
  }) : this(
          parcelId: parcelId,
          status: OutcomeStatus.delivered,
          codCollectedPiasters: codCollectedPiasters,
          recordedAt: recordedAt,
        );

  /// Failed, with a reason. No cash is collected.
  const DeliveryOutcome.failed({
    required String parcelId,
    required FailureReason reason,
    required DateTime recordedAt,
  }) : this(
          parcelId: parcelId,
          status: OutcomeStatus.failed,
          reason: reason,
          recordedAt: recordedAt,
        );

  final String parcelId;
  final OutcomeStatus status;
  final FailureReason? reason;
  final int codCollectedPiasters;

  /// When the courier recorded it. Must be UTC.
  final DateTime recordedAt;

  /// The wire and storage format (also used in the sync request body, after
  /// the entry id): {"parcelId", "status", "reason", "codCollectedPiasters",
  /// "recordedAt"}. `reason` is null for deliveries; `recordedAt` is
  /// `toIso8601String()` of the UTC time, ending in "Z".
  Map<String, Object?> toJson() => {
        'parcelId': parcelId,
        'status': status.name,
        'reason': reason?.name,
        'codCollectedPiasters': codCollectedPiasters,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
      };

  /// Reads what [toJson] wrote. Throws [FormatException] on bad input.
  factory DeliveryOutcome.fromJson(Map<String, Object?> json) {
    final parcelId = json['parcelId'];
    final status = json['status'];
    final reason = json['reason'];
    final cod = json['codCollectedPiasters'];
    final recordedAt = json['recordedAt'];
    if (parcelId is! String || status is! String || cod is! int ||
        recordedAt is! String || (reason != null && reason is! String)) {
      throw FormatException('bad outcome: $json');
    }
    return DeliveryOutcome(
      parcelId: parcelId,
      status: OutcomeStatus.values.byName(status),
      reason: reason == null ? null : FailureReason.values.byName(reason as String),
      codCollectedPiasters: cod,
      recordedAt: DateTime.parse(recordedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DeliveryOutcome &&
      other.parcelId == parcelId &&
      other.status == status &&
      other.reason == reason &&
      other.codCollectedPiasters == codCollectedPiasters &&
      other.recordedAt == recordedAt;

  @override
  int get hashCode =>
      Object.hash(parcelId, status, reason, codCollectedPiasters, recordedAt);

  @override
  String toString() => 'DeliveryOutcome($parcelId, ${status.name}'
      '${reason == null ? '' : ', ${reason!.name}'}, $codCollectedPiasters)';
}
