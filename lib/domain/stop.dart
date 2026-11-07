/// Where a stop is in the courier's day.
enum StopStatus { pending, delivered, failed }

/// One stop on today's route.
final class Stop {
  const Stop({
    required this.id,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.codPiasters,
    this.status = StopStatus.pending,
  });

  final String id;
  final String customerName;
  final String address;
  final String phone;

  /// Cash on delivery to collect, in piasters (EGP 450 = 45000).
  final int codPiasters;
  final StopStatus status;
}
