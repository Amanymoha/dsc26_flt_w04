# AI Usage Documentation - dsc26-flt-w04

## Tools Used
- Bash for file and PDF inspection (`pdfinfo`, `pdftotext`).
- Read for analyzing Dart files.
- Write for implementing/fixing code in `outbox.dart`, `tawseel_stops_app.dart`, `stop_tile.dart`, and `sync_banner.dart`.
- Task tracking tools for managing implementation steps.

## Best Prompts
- "Implement Outbox class and retryDelay function in lib/data/outbox.dart according to all specifications (validation, persistence, HTTP sending, single flight, error handling, corrections, retry delay)."
- "Fix UI widgets in lib/ui/stops/ including breakpoint layout (600px), tap targets (48x48), text scale support, sync banner semantics, and RTL support."

## Bug Found
During implementation, I initially used `queue.removeWhere` in the `sync` loop while iterating, which caused logic errors. I fixed this by using an indexed approach (`queue.removeAt(entryIndex)`) and ensuring the queue is re-saved to the `LocalStore` after every mutation to maintain the required consistency.

## Explanations

**Why is a 409 treated as success?**
A 409 Conflict status indicates that the server has already processed the outcome (it's a "conflict" because it already exists). From the perspective of the outbox, the goal is for the server to have the outcome; since it already does, the local entry is considered successfully synced and should be removed to avoid future attempts.

**Why is a correction appended rather than replacing an entry that has already been attempted?**
If an entry has already been attempted (attempts > 0), the server might have partially processed it or it might be in a transient state. Appending a new correction (or a new outcome for the same parcel) ensures that the sequence of events is preserved and avoids potential race conditions or state corruption on the backend that could occur if we tried to modify an entry that is currently "in flight" or has already been partially acted upon. Replacing only applies when the entry has never been sent (attempts == 0), ensuring we don't send incorrect data.
