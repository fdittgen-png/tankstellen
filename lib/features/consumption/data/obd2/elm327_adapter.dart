import 'elm327_commands.dart';

/// Per-adapter ELM327 protocol quirks (#1330).
///
/// Phase 1: scaffolding only. The single implementation
/// [GenericElm327Adapter] reproduces today's hardcoded init sequence +
/// timing exactly. Phases 2 and 3 add vLinker and SmartOBD profiles
/// with empirically-tuned values.
///
/// The connect path (currently in [Obd2Service.connect] and
/// [Obd2ConnectionService.connect]) consults this object instead of
/// hardcoded constants:
///
///   * [initSequence] — the AT setup commands sent in order after the
///     byte channel is open.
///   * [postResetDelay] — delay applied after the very first init
///     command (typically `ATZ`). Some clones need extra time to
///     re-enumerate after a soft reset.
///   * [interCommandDelay] — delay between subsequent init commands.
///   * [extraInitCommands] — adapter-specific commands appended to the
///     [initSequence] (e.g. `ATSP6\r` to pin a protocol).
///   * [preParse] — hook to massage a raw response BEFORE it reaches
///     the [Elm327Parsers.cleanResponse] pipeline. Default is identity;
///     adapter-specific subclasses can strip stray prompts / echoes.
abstract class Elm327Adapter {
  /// Stable identifier (`generic`, `vlinker-fs`, `smartobd`) used in
  /// debug logs and trip-history adapter attribution.
  String get id;

  /// Init commands sent after the byte channel is open, in order.
  List<String> get initSequence;

  /// Delay applied after the very first init command (typically `ATZ`).
  Duration get postResetDelay;

  /// Delay between subsequent init commands.
  Duration get interCommandDelay;

  /// Optional adapter-specific commands appended to [initSequence].
  List<String> get extraInitCommands;

  /// Hook to massage a raw response before [Elm327Parsers.cleanResponse].
  /// Default: identity. Adapter-specific subclasses can strip stray
  /// echoes etc.
  String preParse(String raw) => raw;
}

/// Default adapter — values mirror today's hardcoded behaviour
/// byte-for-byte (#1330 phase 1). Used for every paired adapter until
/// phases 2/3 introduce vLinker / SmartOBD specialisations.
class GenericElm327Adapter implements Elm327Adapter {
  const GenericElm327Adapter();

  @override
  String get id => 'generic';

  @override
  List<String> get initSequence => Elm327Commands.initCommands;

  @override
  Duration get postResetDelay => const Duration(milliseconds: 100);

  @override
  Duration get interCommandDelay => const Duration(milliseconds: 100);

  @override
  List<String> get extraInitCommands => const [];

  @override
  String preParse(String raw) => raw;
}
