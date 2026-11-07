import 'package:dsc26_flt_w04/data/local_store.dart';
import 'package:dsc26_flt_w04/data/outbox.dart';
import 'package:dsc26_flt_w04/domain/delivery_outcome.dart';
import 'package:dsc26_flt_w04/ui/sample_data.dart';
import 'package:dsc26_flt_w04/ui/stops/tawseel_stops_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final base = Uri.parse('https://api.tawseel.test');
var _n = 0;
String nextId() => 'id-${++_n}';

DeliveryOutcome delivered(String parcel, int piasters) =>
    DeliveryOutcome.delivered(
      parcelId: parcel,
      codCollectedPiasters: piasters,
      recordedAt: DateTime.utc(2026, 11, 2, 10, 30),
    );

void main() {
  setUp(() => _n = 0);

  test('recorded outcomes survive a restart', () async {
    final store = InMemoryLocalStore();
    final client = MockClient((_) async => http.Response('', 503));
    await Outbox(store: store, client: client, baseUrl: base, newId: nextId)
        .record(delivered('P1', 45000));
    final reopened =
        Outbox(store: store, client: client, baseUrl: base, newId: nextId);
    expect((await reopened.pending()).map((e) => e.outcome.parcelId), ['P1']);
  });

  test('sync sends in order with an Idempotency-Key and empties the queue',
      () async {
    final keys = <String>[];
    final client = MockClient((request) async {
      keys.add(request.headers['Idempotency-Key']!);
      return http.Response('{}', 201);
    });
    final outbox = Outbox(
        store: InMemoryLocalStore(), client: client, baseUrl: base, newId: nextId);
    await outbox.record(delivered('P1', 45000));
    await outbox.record(delivered('P2', 0));
    final report = await outbox.sync();
    expect(keys, ['id-1', 'id-2']);
    expect(report.sent, 2);
    expect(await outbox.pending(), isEmpty);
  });

  test('retryDelay doubles from 5 seconds', () {
    expect(retryDelay(1), const Duration(seconds: 5));
    expect(retryDelay(3), const Duration(seconds: 20));
  });

  testWidgets('one pane at 360 px, two panes at 800 px', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 740);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TawseelStopsApp(stops: sampleStops, pendingCount: 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('layout-compact')), findsOneWidget);
    tester.view.physicalSize = const Size(800, 1000);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('layout-expanded')), findsOneWidget);
  });

  testWidgets('meets tap target and label guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(TawseelStopsApp(stops: sampleStops, pendingCount: 3));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(find.bySemanticsLabel('3 outcomes waiting to sync'), findsOneWidget);
    handle.dispose();
  });
}
