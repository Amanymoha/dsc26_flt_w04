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
    return SizedBox(
      height: 64,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              left: 12,
              top: 26,
              child: Container(
                key: Key('stop-dot-${stop.id}'),
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stop.customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(stop.address, maxLines: 1),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 16,
              child: IconButton(
                key: Key('call-${stop.id}'),
                icon: const Icon(Icons.call, size: 18),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tight(const Size(32, 32)),
                onPressed: onCall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
