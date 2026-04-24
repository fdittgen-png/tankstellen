/// Lifecycle phase of the app-wide OBD2 trip recording (#726).
///
/// #797 phase 1 adds [pausedDueToDrop] for the "Bluetooth link lost
/// mid-recording" case. Distinct from [paused] because the user did
/// not pause; the partial trip is auto-persisted to the paused-trips
/// Hive box and a grace timer ticks in the controller. Phase 2 wires
/// this into a banner + auto-reconnect scanner.
enum TripRecordingPhase { idle, recording, paused, pausedDueToDrop, finished }
