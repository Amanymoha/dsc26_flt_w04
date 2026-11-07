import 'package:flutter/material.dart';

import '../../domain/stop.dart';
import 'stop_tile.dart';
import 'sync_banner.dart';

/// Today's stops for one courier.
///
/// Keep this constructor. The screen works on a phone, but it has deliberate
/// problems you must fix (README, Part B): no two-pane layout from 600 px,
/// 32x32 unlabelled call buttons, rows that overflow at 200% text, a banner
/// without a proper semantics label, and a status dot that stays on the left
/// in Arabic.
class TawseelStopsApp extends StatelessWidget {
  const TawseelStopsApp({
    super.key,
    required this.stops,
    required this.pendingCount,
    this.textDirection = TextDirection.ltr,
  });

  final List<Stop> stops;
  final int pendingCount;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tawseel stops',
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          Directionality(textDirection: textDirection, child: child!),
      home: Scaffold(
        appBar: AppBar(title: const Text("Today's stops")),
        body: Column(
          children: [
            SyncBanner(
              key: const Key('sync-banner'),
              pendingCount: pendingCount,
            ),
            Expanded(
              child: KeyedSubtree(
                key: const Key('layout-compact'),
                child: ListView.builder(
                  itemCount: stops.length,
                  itemBuilder: (context, i) => StopTile(
                    key: Key('stop-${stops[i].id}'),
                    stop: stops[i],
                    onTap: () {},
                    onCall: () {},
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
