# Decide: app architecture and state management

Type: grilling
Status: open
Blocked by: 08, 09, 10

## Question

Note (from the content-source decision): the architecture must also cover the **catalog sync path** — the scheduled Supabase edge function maintaining the watch-page → Pixeldrain mapping, the client's cache/refresh of it, and the vendored metadata snapshot's update story.

With the playback stack, backend, and download design known, what is the app's architecture? Decide: state management (e.g. Riverpod vs BLoC) and why; project/module structure; the local persistence layer (catalog cache, progress store, download registry — e.g. Drift vs Hive vs Isar) and how it plays with the sync backend's offline story; and how platform differences (desktop vs mobile layouts, storage, notifications) are isolated so the codebase stays one app, not four.
