import '../elm327_adapter.dart';
import '../elm327_commands.dart';

/// SmartOBD-class ELM327 v1.5 clone (#1330 phase 2).
///
/// These adapters are slower to settle after `ATZ` and need ≥200 ms between
/// subsequent AT commands or the response buffer drifts (a previous
/// command's `OK>` arrives during the next read). Some firmware revisions
/// also emit stray `>` prompt characters mid-frame; [preParse] strips them
/// before the global parser sees the response.
class SmartObdAdapter implements Elm327Adapter {
  const SmartObdAdapter();

  @override
  String get id => 'smart-obd';

  @override
  List<String> get initSequence => Elm327Commands.initCommands;

  @override
  Duration get postResetDelay => const Duration(milliseconds: 400);

  @override
  Duration get interCommandDelay => const Duration(milliseconds: 200);

  @override
  List<String> get extraInitCommands => const [];

  @override
  String preParse(String raw) {
    // Strip stray `>` prompt characters that some SmartOBD firmware
    // emits mid-frame. The terminating `>` is still valid and is removed
    // by Elm327Parsers.cleanResponse downstream.
    if (raw.isEmpty) return raw;
    final lastIdx = raw.lastIndexOf('>');
    if (lastIdx <= 0) return raw;
    final body = raw.substring(0, lastIdx).replaceAll('>', '');
    return body + raw.substring(lastIdx);
  }
}
