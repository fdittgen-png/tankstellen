// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3379 — whether [e] is the EXPECTED Classic-SPP link-drop signature, as
/// opposed to an unexpected fault worth an ERROR trace.
///
/// An RFCOMM reader stream surfaces a closed link as `bt socket closed,
/// read return: -1` (or `… not connected`) on every normal session end —
/// engine off, drive away, navigate off the trip screen, adapter unplugged.
/// That drop is already handled (the channel `_signalDrop`s it to the
/// reconnect controller), so it is breadcrumbed rather than ERROR-logged;
/// only a NON-matching socket error keeps the full error trace.
///
/// Pure + case-insensitive substring match — the message text is the only
/// stable signal the platform layer carries across OEM BT stacks.
/// (Moved out of `classic_elm_channel.dart` for the #1680 file-length cap
/// when #3731 grew the channel's death-edge handling.)
bool isBenignClassicLinkDrop(Object e) {
  final m = e.toString().toLowerCase();
  return m.contains('socket closed') ||
      m.contains('read ret') || // "read ret: -1" and "read return: -1"
      m.contains('not connected');
}
