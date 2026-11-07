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
class TawseelStopsApp extends StatefulWidget {
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
  State<TawseelStopsApp> createState() => _TawseelStopsAppState();
}

class _TawseelStopsAppState extends State<TawseelStopsApp> {
  Stop? _selectedStop;

  @override
  void initState() {
    super.initState();
    if (widget.stops.isNotEmpty) {
      _selectedStop = widget.stops.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedStop == null && widget.stops.isNotEmpty) {
      _selectedStop = widget.stops.first;
    }

    final listWidget = ListView.builder(
      itemCount: widget.stops.length,
      itemBuilder: (context, i) {
        final stop = widget.stops[i];
        return StopTile(
          key: Key('stop-${stop.id}'),
          stop: stop,
          onTap: () {
            setState(() {
              _selectedStop = stop;
            });
          },
          onCall: () {},
        );
      },
    );

    return MaterialApp(
      title: 'Tawseel stops',
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          Directionality(textDirection: widget.textDirection, child: child!),
      home: Scaffold(
        appBar: AppBar(title: const Text("Today's stops")),
        body: Column(
          children: [
            SyncBanner(
              key: const Key('sync-banner'),
              pendingCount: widget.pendingCount,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 600) {
                    return Row(
                      key: const Key('layout-expanded'),
                      children: [
                        SizedBox(width: 320, child: listWidget),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: Container(
                            key: const Key('stop-detail'),
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                _selectedStop?.customerName ?? '',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return KeyedSubtree(
                      key: const Key('layout-compact'),
                      child: listWidget,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
