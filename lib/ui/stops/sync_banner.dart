import 'package:flutter/material.dart';

/// Shows how many outcomes are waiting to sync.
///
/// Works, but has problems (see the README, Part B).
class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key, required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: pendingCount == 0 ? Colors.green.shade100 : Colors.orange.shade100,
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: Text(pendingCount == 0 ? 'Synced' : '$pendingCount pending'),
    );
  }
}
