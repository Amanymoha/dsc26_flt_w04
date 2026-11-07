import 'package:flutter/material.dart';

import 'ui/sample_data.dart';
import 'ui/stops/tawseel_stops_app.dart';

void main() {
  runApp(const TawseelStopsApp(stops: sampleStops, pendingCount: 2));
}
