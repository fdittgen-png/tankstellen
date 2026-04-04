import 'package:flutter/material.dart';

/// Join existing database step: QR scan or manual URL+key entry.
class WizardJoinExisting extends StatelessWidget {
  final TextEditingController urlController;
  final TextEditingController keyController;
  final Widget keyField;
  final VoidCallback onScanQr;
  final VoidCallback? onContinue;

  const WizardJoinExisting({
    super.key,
    required this.urlController,
    required this.keyController,
    required this.keyField,
    required this.onScanQr,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Join an existing database', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),

        // QR Scanner
        FilledButton.icon(
          onPressed: onScanQr,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan QR Code'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 8),
        Text(
          'Ask the database owner to show you their QR code\n(Settings → TankSync → Share)',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),
        const Row(children: [
          Expanded(child: Divider()),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('or')),
          Expanded(child: Divider()),
        ]),
        const SizedBox(height: 24),

        // Manual entry
        Text('Enter manually', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Supabase URL',
            hintText: 'https://your-project.supabase.co',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link),
            helperText: 'Whitespace and line breaks removed automatically',
          ),
          maxLines: 1,
        ),
        const SizedBox(height: 12),
        keyField,
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onContinue,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
