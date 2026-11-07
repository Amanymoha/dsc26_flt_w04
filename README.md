# dsc26-flt-w04 · Tawseel outbox: delivery outcomes that never get lost

DSC Summer Internship 2026 · Flutter track · Week 4 · **Flutter 3.47.6, Dart 3.13, `http` 1.6.0** · expected time 3–4 hours (about 2.5 h on the outbox, 1 h on the screen)

## Scenario

Tawseel couriers record what happened at each stop: delivered with the cash collected, or failed with a reason. They are often offline. You build the **outbox** that stores those outcomes on the phone and syncs them to the dispatch backend later. You also fix the **stop-list screen** so that it works on a small phone with large text, on a tablet in the hub, and in Arabic.

## Getting started

1. **Use this template** → a **public** repository in your own account named exactly **`dsc26-flt-w04`**.
2. `flutter pub get`, then `flutter test` (the public tests fail until you implement the task).

Do **not** rename the package (`name: dsc26_flt_w04`). A renamed package scores 0.

## File layout

```text
lib/
  main.dart                          demo app (given)
  domain/delivery_outcome.dart       DeliveryOutcome, OutcomeStatus, FailureReason, toJson/fromJson (given, do not change)
  domain/stop.dart                   Stop, StopStatus (given, do not change)
  data/local_store.dart              LocalStore, InMemoryLocalStore, SharedPreferencesLocalStore (given, do not change)
  data/outbox.dart                   OutboxEntry, SyncReport (given); Outbox and retryDelay (you write them)
  ui/sample_data.dart                sampleStops, including one long Arabic address (given)
  ui/stops/tawseel_stops_app.dart    TawseelStopsApp: works, but flawed (you fix it)
  ui/stops/stop_tile.dart            flawed row
  ui/stops/sync_banner.dart          flawed banner
test/public_test.dart
AI_USAGE.md
```

You may add files under `lib/ui/stops/` and restructure the UI freely. Keep `TawseelStopsApp`'s constructor and the keys.

## Part A: the outbox (`lib/data/outbox.dart`)

```dart
class Outbox {
  Outbox({required LocalStore store, required http.Client client,
          required Uri baseUrl, required String Function() newId});

  Future<OutboxEntry> record(DeliveryOutcome outcome);
  Future<List<OutboxEntry>> pending();   // in send order
  Future<List<OutboxEntry>> rejected();
  Future<int> pendingCount();
  Future<SyncReport> sync();
}

Duration retryDelay(int consecutiveFailures);
```

`OutboxEntry` (`id`, `outcome`, `attempts`, `status`: pending or rejected, `rejectionReason`, with `copyWith`, `toJson`, `fromJson`) and `SyncReport` are given.

1. **Validation.** `record` throws `ArgumentError` and **stores nothing** unless all of these hold:
   - `parcelId` is non-empty;
   - `recordedAt.isUtc`;
   - a `delivered` outcome has `codCollectedPiasters >= 0` and no reason;
   - a `failed` outcome has a reason and `codCollectedPiasters == 0`.
2. **Persist before you confirm.** `record` writes the whole queue to `store` under the key **`tawseel.outbox.v1`** (any valid JSON you like) and **awaits that write before its own future completes**. A new `Outbox` on the same `store` (that is what an app restart looks like) sees the same entries, with the same ids, in the same order. `sync` also writes the queue after every change it makes (attempt counts, removals, rejections), so a restart after a sync sees the current state.
3. **New entries** get `id = newId()`, `attempts = 0`, status pending. Call `newId()` only when you append a new entry.
4. **Corrections.** If a **pending** entry for the same `parcelId` exists with `attempts == 0` (never sent), the new outcome **replaces** it in place (same id, same position). Otherwise the new outcome is **appended** as a new entry.
5. **Sending.** `sync` sends pending entries one at a time, oldest first: `POST {baseUrl}/v1/outcomes`.
   - Headers: `Content-Type: application/json` and `Idempotency-Key: <entry id>`.
   - Body: `{"id": <entry id>, ...outcome.toJson()}`, which gives the fields `id`, `parcelId`, `status`, `reason` (the enum name, e.g. `"customerNotHome"`, **null** for deliveries, but present), `codCollectedPiasters` and `recordedAt` (`toIso8601String()` of the UTC time, ending in `Z`).
   - Each send increments that entry's `attempts`, whatever happens.
6. **Responses:**

| Answer | What happens |
|---|---|
| 200, 201, 409 | Remove the entry: the server has it (409 means "already have it"). Counts as `sent`. |
| 400, 422 | Mark it rejected. `rejectionReason` is the `message` string from a JSON body `{"message": ...}` if there is one, otherwise `HTTP <code>`. Counts as `rejected`. **Continue with the next entry.** |
| 401 | Stop the run with `authRequired: true` (no `retryAfter`). The entry stays pending. |
| anything else, or `http.ClientException` | Stop the run. **Do not skip ahead.** The entry stays at the front, and `retryAfter = retryDelay(attempts of that entry)`. |

7. **Single flight.** Calling `sync()` while a sync is running returns the **same future**, so no entry is sent twice. Once the run ends, the next `sync()` starts a new run. An outcome recorded during a run must be sent by that run or by the next one, exactly once.
8. **`retryDelay(n)`** = 5 s × 2^(n−1), capped at 300 s (5, 10, 20, 40, 80, 160, then 300 s for every n ≥ 7, including very large n). `n < 1` throws `ArgumentError`.
9. **`SyncReport`:**
   - `sent` and `rejected` count the entries removed and rejected in this run;
   - `remaining` is the number of pending entries after the run;
   - `authRequired` is set when the run stopped on a 401;
   - `retryAfter` is null unless the run stopped on a transient failure.

## Part B: the stop list (`lib/ui/stops/`)

`TawseelStopsApp({required List<Stop> stops, required int pendingCount, TextDirection textDirection = TextDirection.ltr})` works, but has deliberate problems. Fix them:

- **Breakpoint.** From **600** logical pixels of available width (600 included), show the list and the selected stop's details side by side (`layout-expanded`). The details go in a widget keyed `stop-detail`, which must contain a `Text` with exactly the stop's `customerName`. The first stop is selected until the user taps another row. Below 600, show the list only (`layout-compact`, and no `stop-detail`). Decide from the width (`LayoutBuilder` or `MediaQuery.sizeOf`), never from "is it a tablet".
- **Tap targets and labels.** The call buttons are 32×32 with no label. Every tappable control must be at least 48×48 and labelled (for an `IconButton`, a `tooltip` such as `Call Mona Adel`).
- **200% text.** At 200% text on a 360×740 screen the rows overflow. They must not, in LTR or RTL, including the long Arabic address. Do not use fixed heights around text, and let rows grow.
- **Sync banner** (`sync-banner`). It must expose **exactly one** semantics label, and that label must be the whole label of its node (no extra text merged in):
  - `All outcomes synced` when `pendingCount` is 0;
  - `1 outcome waiting to sync`;
  - `N outcomes waiting to sync` for N ≥ 2.

  It must also be a live region (`Semantics(liveRegion: true, ...)`).
- **RTL.** The status dot (`stop-dot-<id>`) sits on the **start** side of its row: the left in LTR, the right in RTL. Use `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional` or a `ListTile`'s `leading`, never `left:`/`right:`.

**Keys the tests use:**

| Key | Widget |
|---|---|
| `layout-compact` | The one-pane layout (below 600 px) |
| `layout-expanded` | The two-pane layout (600 px and up) |
| `sync-banner` | The sync banner |
| `stop-<id>` | One row per stop (tappable; selects the stop) |
| `stop-dot-<id>` | The status dot in that row |
| `call-<id>` | The call button in that row |
| `stop-detail` | The detail pane in the two-pane layout |

The hidden tests use their own stops, not `sampleStops`. They run at 360×740, 599, 600, 800×600 and 1024×768 logical pixels, with text scales 1.0 and 2.0, in LTR and RTL. They check the Android tap-target and labelled-tap-target guidelines through the semantics tree, so hiding widgets from semantics does not help.

## How grading works

Push, then press **Submit for grading** on DSC Hex (5 attempts per task per day). The grader copies your `lib/` into a clean project with the pinned packages, adds the hidden tests and runs `flutter test` on Flutter 3.47.6 with the network off: 10-minute limit, 30 s per test. Every HTTP call goes to a fake server that records each request.

| Row | Public name | Weight |
|---|---|---|
| H01 | record: validation | 6 |
| H02 | record: persistence | 8 |
| H03 | sync: request format | 8 |
| H04 | sync: success codes | 6 |
| H05 | sync: permanent rejection | 8 |
| H06 | sync: transient failure | 8 |
| H07 | sync: auth | 5 |
| H08 | sync: single flight | 8 |
| H09 | corrections | 8 |
| H10 | retry delay | 5 |
| H11 | layout breakpoint | 8 |
| H12 | accessibility | 12 |
| H13 | text scale and RTL | 10 |

Row score = weight × passed ÷ total. If `lib/` does not compile, you score 0 and see the first compiler errors in your files. Late policy: ×1.0 within 72 hours of the session starting, ×0.6 for the following 7 days, ×0.5 after that until Thu 3 Dec 23:59; W5 reopens W2–W4 at ×1.0. Best attempt counts.

## `AI_USAGE.md` (required)

Fill in: the tools you used; your best prompts; one bug you found in AI-generated outbox or layout code, and how you found it; and, in your own words (three or four sentences), why a 409 is treated as success and why a correction is appended rather than replacing an entry that has already been attempted.
