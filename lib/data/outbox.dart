import 'package:http/http.dart' as http;

import '../domain/delivery_outcome.dart';
import 'local_store.dart';

/// The storage key for the whole queue (a JSON document).
const String outboxStorageKey = 'tawseel.outbox.v1';

enum EntryStatus { pending, rejected }

/// One queued outcome. Immutable; the outbox replaces entries with [copyWith].
final class OutboxEntry {
  const OutboxEntry({
    required this.id,
    required this.outcome,
    this.attempts = 0,
    this.status = EntryStatus.pending,
    this.rejectionReason,
  });

  /// Generated on the phone when the outcome is recorded; sent as the
  /// Idempotency-Key header.
  final String id;
  final DeliveryOutcome outcome;

  /// How many times this entry has been sent, whatever the answer was.
  final int attempts;
  final EntryStatus status;
  final String? rejectionReason;

  OutboxEntry copyWith({
    DeliveryOutcome? outcome,
    int? attempts,
    EntryStatus? status,
    String? rejectionReason,
  }) =>
      OutboxEntry(
        id: id,
        outcome: outcome ?? this.outcome,
        attempts: attempts ?? this.attempts,
        status: status ?? this.status,
        rejectionReason: rejectionReason ?? this.rejectionReason,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'outcome': outcome.toJson(),
        'attempts': attempts,
        'status': status.name,
        'rejectionReason': rejectionReason,
      };

  factory OutboxEntry.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final outcome = json['outcome'];
    final attempts = json['attempts'];
    final status = json['status'];
    final reason = json['rejectionReason'];
    if (id is! String || outcome is! Map || attempts is! int ||
        status is! String || (reason != null && reason is! String)) {
      throw FormatException('bad outbox entry: $json');
    }
    return OutboxEntry(
      id: id,
      outcome: DeliveryOutcome.fromJson(outcome.cast<String, Object?>()),
      attempts: attempts,
      status: EntryStatus.values.byName(status),
      rejectionReason: reason as String?,
    );
  }

  @override
  String toString() =>
      'OutboxEntry($id, ${outcome.parcelId}, attempts: $attempts, ${status.name})';
}

/// What one sync run did.
final class SyncReport {
  const SyncReport({
    required this.sent,
    required this.rejected,
    required this.remaining,
    this.authRequired = false,
    this.retryAfter,
  });

  /// Entries the server accepted in this run (200, 201 or 409).
  final int sent;

  /// Entries the server rejected in this run (400 or 422).
  final int rejected;

  /// Pending entries left after the run.
  final int remaining;

  /// True when the run stopped on a 401.
  final bool authRequired;

  /// Set when the run stopped on a transient failure: wait this long.
  final Duration? retryAfter;

  @override
  String toString() => 'SyncReport(sent: $sent, rejected: $rejected, '
      'remaining: $remaining, authRequired: $authRequired, '
      'retryAfter: $retryAfter)';
}

/// 5 s × 2^(n−1), capped at 300 s. [consecutiveFailures] must be at least 1,
/// otherwise throw ArgumentError.
///
/// TODO(W4): implement.
Duration retryDelay(int consecutiveFailures) {
  throw UnimplementedError('retryDelay');
}

/// An offline-first queue of delivery outcomes. See the README for the rules.
///
/// Keep the constructor and the public method signatures exactly.
class Outbox {
  Outbox({
    required LocalStore store,
    required http.Client client,
    required Uri baseUrl,
    required String Function() newId,
  })  : _store = store,
        _client = client,
        _baseUrl = baseUrl,
        _newId = newId;

  // ignore: unused_field
  final LocalStore _store;
  // ignore: unused_field
  final http.Client _client;
  // ignore: unused_field
  final Uri _baseUrl;
  // ignore: unused_field
  final String Function() _newId;

  /// TODO(W4): validate, queue (or correct), and persist before completing.
  Future<OutboxEntry> record(DeliveryOutcome outcome) async {
    throw UnimplementedError('Outbox.record');
  }

  /// Pending entries, in send order.
  Future<List<OutboxEntry>> pending() async {
    throw UnimplementedError('Outbox.pending');
  }

  Future<List<OutboxEntry>> rejected() async {
    throw UnimplementedError('Outbox.rejected');
  }

  Future<int> pendingCount() async {
    throw UnimplementedError('Outbox.pendingCount');
  }

  /// TODO(W4): send pending entries oldest first; single-flight.
  Future<SyncReport> sync() async {
    throw UnimplementedError('Outbox.sync');
  }
}
