import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../screens/report_screen.dart' show ReportType;

/// The dynamic input field below the radio list: a price TextField for
/// price reports, a free-text TextField for metadata corrections, or
/// nothing for status reports.
class ReportInputSection extends StatelessWidget {
  final ReportType? selectedType;
  final TextEditingController priceController;
  final TextEditingController textController;

  const ReportInputSection({
    super.key,
    required this.selectedType,
    required this.priceController,
    required this.textController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = selectedType;
    if (type == null) return const SizedBox.shrink();

    if (type.needsPrice) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: TextField(
          controller: priceController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n?.correctPrice ?? 'Correct price (e.g. 1.459)',
            prefixText: '\u20ac ',
            border: const OutlineInputBorder(),
          ),
        ),
      );
    }

    if (type.needsText) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: TextField(
          key: const ValueKey('report-correction-text-field'),
          controller: textController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            // TODO: add ARB keys `correctName` / `correctAddress`.
            labelText: type == ReportType.wrongName
                ? 'Nom correct de la station'
                : 'Adresse correcte',
            border: const OutlineInputBorder(),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
