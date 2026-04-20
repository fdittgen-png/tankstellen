import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'theme_mode_provider.dart';

/// Settings tile + radio sheet for the theme-mode preference (#752).
///
/// Same Card + ListTile shape as `SettingsMenuTile`, but the tap opens
/// a bottom sheet with three radio rows (Light / Dark / Follow system)
/// instead of navigating to a new screen — a full screen for a single
/// 3-option choice would be heavy.
class ThemeModeTile extends ConsumerWidget {
  const ThemeModeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final mode = ref.watch(themeModeSettingProvider);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        key: const Key('themeModeTile'),
        leading: Icon(_iconFor(mode), size: 20),
        title: Text(
          l?.themeSettingTitle ?? 'Theme',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _labelFor(mode, l),
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openPicker(context, ref),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _ThemeModePickerSheet(
        current: ref.read(themeModeSettingProvider),
      ),
    );
    if (picked != null) {
      await ref.read(themeModeSettingProvider.notifier).set(picked);
    }
  }

  static IconData _iconFor(ThemeMode mode) => switch (mode) {
        ThemeMode.light => Icons.light_mode,
        ThemeMode.dark => Icons.dark_mode,
        ThemeMode.system => Icons.smartphone,
      };

  static String _labelFor(ThemeMode mode, AppLocalizations? l) =>
      switch (mode) {
        ThemeMode.light => l?.themeModeLight ?? 'Light',
        ThemeMode.dark => l?.themeModeDark ?? 'Dark',
        ThemeMode.system => l?.themeModeSystem ?? 'Follow system',
      };
}

class _ThemeModePickerSheet extends StatelessWidget {
  final ThemeMode current;
  const _ThemeModePickerSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (v) {
            if (v != null) Navigator.of(context).pop(v);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  l?.themeSettingTitle ?? 'Theme',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              _option(
                mode: ThemeMode.light,
                icon: Icons.light_mode,
                label: l?.themeModeLight ?? 'Light',
                keyValue: 'themeModeOptionLight',
              ),
              _option(
                mode: ThemeMode.dark,
                icon: Icons.dark_mode,
                label: l?.themeModeDark ?? 'Dark',
                keyValue: 'themeModeOptionDark',
              ),
              _option(
                mode: ThemeMode.system,
                icon: Icons.smartphone,
                label: l?.themeModeSystem ?? 'Follow system',
                keyValue: 'themeModeOptionSystem',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option({
    required ThemeMode mode,
    required IconData icon,
    required String label,
    required String keyValue,
  }) {
    return RadioListTile<ThemeMode>(
      key: Key(keyValue),
      value: mode,
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
