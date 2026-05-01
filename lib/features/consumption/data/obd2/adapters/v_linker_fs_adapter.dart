import '../elm327_adapter.dart';
import '../elm327_commands.dart';

/// vLinker FS-class adapter (e.g. FS-14884). Faster, cleaner ELM327
/// implementation; the base init sequence is reliable with shorter
/// delays than the generic profile (#1330 phase 2).
class VLinkerFsAdapter implements Elm327Adapter {
  const VLinkerFsAdapter();

  @override
  String get id => 'vlinker-fs';

  @override
  List<String> get initSequence => Elm327Commands.initCommands;

  @override
  Duration get postResetDelay => const Duration(milliseconds: 200);

  @override
  Duration get interCommandDelay => const Duration(milliseconds: 50);

  @override
  List<String> get extraInitCommands => const [];

  @override
  String preParse(String raw) => raw;
}
