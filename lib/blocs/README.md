# blocs

State management. Blocs (event-driven) for the BLE connection state machine and
session recording; Cubits for simpler screens. No Flutter widget imports here.

`watch_sync/` isn't a Cubit: `WatchSync` follows `LiveHeartRateCubit` and sends
each change to the Apple Watch app through `WatchBridge`, as a live message and
as the application context.
