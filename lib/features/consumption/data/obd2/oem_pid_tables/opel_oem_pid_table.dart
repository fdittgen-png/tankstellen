import '../oem_pid_table.dart';
import 'psa_oem_pid_table.dart';

/// Opel / Vauxhall OEM fuel-level table (#1617).
///
/// Post-2017 Opels — Corsa F, Mokka B, Crossland, Grandland — are
/// built on PSA's EMP2 platform after the 2017 Stellantis-era
/// acquisition. Their Body Systems Interface answers the same UDS
/// Read-Data-By-Local-Identifier fuel-level read as the PSA cars:
/// service `0x21`, local identifier `0x51`, transmit header `0x6FA`.
/// This table therefore claims the Opel WMI prefixes and **delegates
/// the read to [PsaOemPidTable]** — the EMP2 BSI is the same silicon.
///
/// Pre-2017 GM-era Opels share the `W0L` WMI but run a GM BSI that
/// does not route this local identifier — they hit [PsaOemPidTable]'s
/// negative-response branch and return `null`, so the caller falls
/// back to the standard PID `0x2F` percentage path exactly as it
/// would for any untabled car.
///
/// Splitting this into its own table — rather than adding `W0L` to
/// [PsaOemPidTable]'s prefix set — keeps the OEM identity honest in
/// diagnostics: [oemKey] reads `OPEL`, not `PSA`. The PSA table's
/// docstring deferred Opel "pending dedicated reverse-engineering";
/// the EMP2-shared-BSI finding is that resolution.
class OpelOemPidTable implements OemPidTable {
  const OpelOemPidTable();

  /// The PSA EMP2 BSI read, reused verbatim — post-2017 Opels share
  /// the exact `0x6FA / 21 51` command and `byte × 0.5` scaling.
  static const PsaOemPidTable _psaBsiRead = PsaOemPidTable();

  /// Opel / Vauxhall passenger-car WMIs. `W0L` is the Opel
  /// (Rüsselsheim / Zaragoza / Gliwice) prefix; `W0V` is the Vauxhall
  /// UK rebadge. Upper-case per the [OemPidTable.supportedWmiPrefixes]
  /// contract.
  static const Set<String> _prefixes = {'W0L', 'W0V'};

  @override
  String get oemKey => 'OPEL';

  @override
  Set<String> get supportedWmiPrefixes => _prefixes;

  @override
  Future<double?> readFuelLevelLitres(Obd2RawCommandPort port) =>
      _psaBsiRead.readFuelLevelLitres(port);
}
