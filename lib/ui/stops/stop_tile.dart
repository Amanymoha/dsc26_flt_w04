import 'package:flutter/material.dart';

import '../../domain/stop.dart';

/// One stop row.
///
/// Works on a phone in English at normal text size, but has problems
/// (see the README, Part B).
class StopTile extends StatelessWidget {
  const StopTile({
    super.key,
    required this.stop,
    required this.onTap,
    required this.onCall,
  });

  final Stop stop;
  final VoidCallback onTap;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final color = switch (stop.status) {
      StopStatus.pending => Colors.amber.shade700,
      StopStatus.delivered => Colors.green.shade700,
      StopStatus.failed => Colors.red.shade700,
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          children: [
            Container(
              key: Key('stop-dot-${stop.id}'),
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stop.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(stop.address),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                key: Key('call-${stop.id}'),
                tooltip: 'Call ${stop.customerName}',
                icon: const Icon(Icons.call, size: 20),
                onPressed: onCall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
