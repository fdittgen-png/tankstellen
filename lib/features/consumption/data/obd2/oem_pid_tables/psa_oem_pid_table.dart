import 'package:flutter/foundation.dart';

import '../oem_pid_table.dart';

/// PSA (Peugeot / Citroën / DS) OEM fuel-level table (#1401 phase 4).
///
/// Reads the exact litres-in-tank value from the Body Systems Interface
/// (BSI) ECU via UDS service `0x21` (Read Data by Local Identifier),
/// local identifier `0x51`. The byte returned by the BSI is scaled
/// `× 0.5` to yield litres — so a `0x5A` byte (90 decimal) maps to
/// 45.0 L. Range covers 0.0 – 127.5 L on a single byte, more than
/// enough for every PSA fuel tank ever produced.
///
/// ## Wire protocol
///
/// After the standard ELM327 init the table issues:
///
/// ```
/// AT SH 6FA\r   // switch transmit header to BSI
/// 2151\r        // service 0x21, LID 0x51 (fuel level)
/// AT SH 7DF\r   // best-effort restore broadcast header
/// ```
///
/// The expected positive response is `67A 03 61 51 XX` where:
///   * `67A` is the BSI's response header (some adapters strip it
///     entirely when ATH0 is in effect — the parser tolerates both
///     shapes).
///   * `03` is the UDS payload length (3 bytes).
///   * `61` is service ID + 0x40 (positive-response echo of `0x21`).
///   * `51` is the echoed local identifier.
///   * `XX` is the fuel-level byte; litres = `XX × 0.5`.
///
/// A negative response of the form `7F 21 XX` (e.g. `7F 21 31`,
/// "subFunctionNotSupported") is returned by older PSAs (pre-2008
/// platform 1) and by non-PSA cars whose BSI cannot route this LID.
/// The parser maps these to `null` so the caller falls back to the
/// standard PID `0x2F` percentage path. Any other unparseable response
/// (empty, garbage, truncated) also returns `null` — *never* an
/// exception. The trip-recording fuel sampler treats a null result as
/// "fall back" — never as "tank is empty".
///
/// ## WMI prefixes claimed
///
/// The four prefixes covered here (`VF3`, `VF7`, `VR1`, `VR3`) are
/// PSA's France/Stellantis-era passenger-car WMIs as catalogued in
/// `lib/features/vehicle/data/wmi_table.dart`:
///
/// | Prefix | Brand    | Source            |
/// |--------|----------|-------------------|
/// | VF3    | Peugeot  | wmi_table.dart    |
/// | VF7    | Citroën  | wmi_table.dart    |
/// | VR1    | Citroën  | wmi_table.dart    |
/// | VR3    | Peugeot  | wmi_table.dart    |
///
/// The `0x6FA / 21 51` command is documented for the post-2008 PSA
/// platform 2 / EMP2 BSI generation (308 / 3008 / 508 et al.). Older
/// PSAs that share these WMI prefixes will return the negative-response
/// path and fall back gracefully to PID `0x2F`. Opel (`W0L`) was
/// acquired by PSA in 2017 but uses a distinct BSI architecture —
/// not claimed here pending dedicated reverse-engineering.
class PsaOemPidTable implements OemPidTable {
  const PsaOemPidTable();

  /// Pre-allocated set so const-construction stays cheap and the
  /// registry can hand the same instance back repeatedly without
  /// allocating a new set each time it inspects the prefixes.
  static const Set<String> _prefixes = {'VF3', 'VF7', 'VR1', 'VR3'};

  /// `AT SH` value that points the adapter at the BSI's RX address.
  /// PSA uses `0x6FA` for the diagnostic tester → BSI request frame;
  /// the BSI responds on `0x67A`. The `\r` terminator matches the
  /// existing [Elm327Commands] convention so [Obd2RawCommandPort]
  /// implementations can pass it through verbatim.
  @visibleForTesting
  static const String setBsiHeaderCommand = 'AT SH 6FA\r';

  /// UDS Read-Data-By-Local-Identifier request: service `0x21`, LID
  /// `0x51` (fuel level on the PSA BSI platform 2 / EMP2 generation).
  @visibleForTesting
  static const String fuelLevelCommand = '2151\r';

  /// Restore the broadcast header (`0x7DF`, OBD-II functional
  /// addressing) so the next caller's vanilla mode-01 PID isn't routed
  /// at the BSI by accident. Best-effort — failure is swallowed; the
  /// next OEM read would re-issue `AT SH` anyway.
  @visibleForTesting
  static const String restoreBroadcastHeaderCommand = 'AT SH 7DF\r';

  @override
  String get oemKey => 'PSA';

  @override
  Set<String> get supportedWmiPrefixes => _prefixes;

  @override
  Future<double?> readFuelLevelLitres(Obd2RawCommandPort port) async {
    // Switch the adapter to BSI's address. Some clones reject `AT SH`
    // entirely; if the response carries an explicit "?" or "ERROR" we
    // bail out before sending the data request — there's nothing to
    // parse and the caller will fall back to PID 0x2F.
    final headerAck = await port.sendRaw(setBsiHeaderCommand);
    if (_isAdapterError(headerAck)) {
      // Don't even try the data request — keeps the OBD-II loop from
      // hanging on a guaranteed timeout.
      return null;
    }

    final raw = await port.sendRaw(fuelLevelCommand);
    final litres = parsePsaFuelLevelLitres(raw);

    // Best-effort restore of the broadcast header so subsequent
    // standard-PID reads don't accidentally target the BSI. Failure
    // is fine — the next OEM read would re-issue AT SH anyway, and
    // this is documented as best-effort in the class docstring.
    try {
      await port.sendRaw(restoreBroadcastHeaderCommand);
    } on Object {
      // Intentional swallow — port contract says it shouldn't throw,
      // but we don't want a single misbehaving adapter to bubble an
      // unrelated error up through a successful litres read.
    }

    return litres;
  }
}

/// Detect adapter-side rejection of an `AT SH` (or any other AT)
/// command. Real ELM327s answer `OK\r>`; clones that don't support
/// header-switching answer `?\r>` or `ERROR\r>` (occasionally
/// `STOPPED`). An empty response means the port couldn't even round-
/// trip — also a hard-fail signal.
bool _isAdapterError(String raw) {
  final cleaned = raw.replaceAll('>', '').trim().toUpperCase();
  if (cleaned.isEmpty) return true;
  if (cleaned.contains('?')) return true;
  if (cleaned.contains('ERROR')) return true;
  if (cleaned.contains('STOPPED')) return true;
  if (cleaned.contains('UNABLE')) return true;
  return false;
}

/// Pure parser for the BSI fuel-level response (#1401 phase 4).
///
/// Tolerates the response shapes a real ELM327 produces:
///   * full headered `'67A 03 61 51 XX'`,
///   * header-stripped (ATH0) `'03 61 51 XX'`,
///   * `'61 51 XX'` (some adapters drop the length byte too),
///   * lower-case hex, mixed whitespace, prompt-character noise (`>`),
///   * the original request echoed on its own line above the
///     response (`'2151\r67A 03 61 51 5A'`).
///
/// Returns `null` for:
///   * empty / whitespace / null,
///   * negative response `7F 21 XX`,
///   * any frame that doesn't carry the `61 51` echo,
///   * a fuel-level byte that fails hex parsing.
///
/// Litres are derived as `byte * 0.5` per PSA BSI scaling. The byte
/// range is the full unsigned 0..255, mapping to 0.0..127.5 L.
double? parsePsaFuelLevelLitres(String? raw) {
  if (raw == null) return null;

  // Normalise whitespace, prompt characters and case. The ELM327
  // delivers `\r`-separated frames with a trailing `>` prompt; some
  // adapters also echo the request back on its own line.
  final cleaned = raw.replaceAll('>', ' ').trim();
  if (cleaned.isEmpty) return null;

  // Walk every line so we can ignore the echoed request. A single-
  // line response (most adapters with ATE0) hits this loop once.
  for (final line in cleaned.split(RegExp(r'[\r\n]+'))) {
    final tokens = line
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map((t) => t.toUpperCase())
        .toList();
    if (tokens.isEmpty) continue;

    // Ignore the echoed request line (`2151`) — same prefix the
    // table sent — so we don't mistake it for a malformed response.
    if (tokens.length == 1 && tokens.first == '2151') continue;

    // Negative response: `7F 21 XX`. Branch BEFORE searching for the
    // `61 51` echo so we return null cleanly without falling through
    // to the "no payload found" branch.
    if (tokens.length >= 2 && tokens[0] == '7F' && tokens[1] == '21') {
      return null;
    }

    // Search for the `61 51 XX` payload anywhere in the token stream.
    // This naturally handles all three header shapes above without
    // committing to a specific framing.
    for (var i = 0; i + 2 < tokens.length; i++) {
      if (tokens[i] == '61' && tokens[i + 1] == '51') {
        final byte = int.tryParse(tokens[i + 2], radix: 16);
        if (byte == null) return null;
        return byte * 0.5;
      }
    }
  }

  return null;
}
