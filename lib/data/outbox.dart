import 'dart:convert';
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
  if (consecutiveFailures < 1) throw ArgumentError('n < 1');
  if (consecutiveFailures >= 7) return const Duration(seconds: 300);
  return Duration(seconds: 5 * (1 << (consecutiveFailures - 1)));
}

/// An offline-first queue of delivery outcomes. See the README for the rules.
///
/// Keep the constructor and the public method signatures exactly.
class Outbox {
  Outbox({
    required this._store,
    required http.Client client,
    required this._baseUrl,
    required this._newId,
  })  : _client = client;

  // ignore: unused_field
  final LocalStore _store;
  // ignore: unused_field
  final http.Client _client;
  // ignore: unused_field
  final Uri _baseUrl;
  // ignore: unused_field
  final String Function() _newId;

  Future<List<OutboxEntry>> _loadQueue() async {
    final jsonString = await _store.read(outboxStorageKey);
    if (jsonString == null) return [];
    final list = json.decode(jsonString) as List;
    return list.map((e) => OutboxEntry.fromJson(e as Map<String, Object?>)).toList();
  }

  Future<void> _saveQueue(List<OutboxEntry> entries) async {
    final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
    await _store.write(outboxStorageKey, jsonString);
  }

  /// TODO(W4): validate, queue (or correct), and persist before completing.
  Future<OutboxEntry> record(DeliveryOutcome outcome) async {
    if (outcome.parcelId.isEmpty) throw ArgumentError('parcelId is empty');
    if (!outcome.recordedAt.isUtc) throw ArgumentError('recordedAt is not UTC');
    if (outcome.status == OutcomeStatus.delivered && (outcome.codCollectedPiasters < 0 || outcome.reason != null)) {
       throw ArgumentError('Invalid delivered outcome');
    }
    if (outcome.status == OutcomeStatus.failed && (outcome.reason == null || outcome.codCollectedPiasters != 0)) {
       throw ArgumentError('Invalid failed outcome');
    }

    final queue = await _loadQueue();
    final index = queue.indexWhere((e) => e.outcome.parcelId == outcome.parcelId && e.attempts == 0);

    final OutboxEntry entry;
    if (index != -1) {
      entry = queue[index].copyWith(outcome: outcome);
      queue[index] = entry;
    } else {
      entry = OutboxEntry(id: _newId(), outcome: outcome);
      queue.add(entry);
    }

    await _saveQueue(queue);
    return entry;
  }

  /// Pending entries, in send order.
  Future<List<OutboxEntry>> pending() async {
    return (await _loadQueue()).where((e) => e.status == EntryStatus.pending).toList();
  }

  Future<List<OutboxEntry>> rejected() async {
    return (await _loadQueue()).where((e) => e.status == EntryStatus.rejected).toList();
  }

  Future<int> pendingCount() async {
    return (await pending()).length;
  }

  Future<SyncReport>? _running;

  /// TODO(W4): send pending entries oldest first; single-flight.
  Future<SyncReport> sync() => _running ??= _syncOnce().whenComplete(() => _running = null);

   Future<SyncReport> _syncOnce() async {
    var queue = await _loadQueue();
    int sent = 0;
    int rejected = 0;
    bool authRequired = false;
    Duration? retryAfter;

    while (true) {
      final pending = queue.where((e) => e.status == EntryStatus.pending).toList();
      if (pending.isEmpty) break;

      final entry = pending.first;
      final entryIndex = queue.indexOf(entry);

      final body = {'id': entry.id, ...entry.outcome.toJson()};
      
      // التعديل هنا: إضافة try-catch
      http.Response response;
      try {
        response = await _client.post(
          Uri.parse('${_baseUrl.toString()}/v1/outcomes'),
          headers: {'Content-Type': 'application/json', 'Idempotency-Key': entry.id},
          body: json.encode(body),
        );
      } catch (_) {
        // في حالة حدوث ClientException أو أي خطأ شبكة، توقف وأرجع retryAfter
        retryAfter = retryDelay(queue[entryIndex].attempts);
        break;
      }

      queue[entryIndex] = queue[entryIndex].copyWith(attempts: queue[entryIndex].attempts + 1);

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 409) {
        queue.removeAt(entryIndex);
        sent++;
        await _saveQueue(queue);
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        String? reason;
        try {
          final jsonBody = json.decode(response.body);
          reason = jsonBody['message'] as String?;
        } catch (_) {}
        queue[entryIndex] = queue[entryIndex].copyWith(status: EntryStatus.rejected, rejectionReason: reason ?? response.statusCode.toString());
        rejected++;
        await _saveQueue(queue);
      } else if (response.statusCode == 401) {
        authRequired = true;
        break;
      } else {
        retryAfter = retryDelay(queue[entryIndex].attempts);
        break;
      }
    }

    return SyncReport(sent: sent, rejected: rejected, remaining: queue.where((e) => e.status == EntryStatus.pending).length, authRequired: authRequired, retryAfter: retryAfter);
  }
}
