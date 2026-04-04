import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/sync/schema_verifier.dart';

/// Schema verification step: shows table status and migration SQL.
class WizardSchemaStep extends StatelessWidget {
  final Map<String, bool>? schemaStatus;
  final String? migrationSql;
  final VoidCallback onRecheck;
  final VoidCallback onDone;

  const WizardSchemaStep({
    super.key,
    required this.schemaStatus,
    required this.migrationSql,
    required this.onRecheck,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (schemaStatus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final allReady = SchemaVerifier.requiredTables.every((t) => schemaStatus![t] == true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          allReady ? Icons.check_circle : Icons.warning_amber,
          size: 48,
          color: allReady ? Colors.green : Colors.orange,
        ),
        const SizedBox(height: 16),
        Text(
          allReady ? 'Database ready!' : 'Database needs setup',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Table status list
        for (final table in [...SchemaVerifier.requiredTables, ...SchemaVerifier.optionalTables])
          ListTile(
            dense: true,
            leading: Icon(
              schemaStatus![table] == true ? Icons.check_circle : Icons.cancel,
              color: schemaStatus![table] == true ? Colors.green : Colors.red,
              size: 18,
            ),
            title: Text(table, style: theme.textTheme.bodySmall),
            trailing: Text(
              schemaStatus![table] == true ? 'OK' : 'Missing',
              style: TextStyle(
                fontSize: 11,
                color: schemaStatus![table] == true ? Colors.green : Colors.red,
              ),
            ),
          ),

        if (!allReady) ...[
          const SizedBox(height: 16),
          Text(
            'Copy the SQL below and run it in your Supabase SQL Editor\n'
            '(Dashboard → SQL Editor → New Query → Paste → Run)',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: migrationSql ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SQL copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy SQL to clipboard'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRecheck,
            icon: const Icon(Icons.refresh),
            label: const Text('Re-check schema'),
          ),
        ],

        if (allReady) ...[
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onDone,
            child: const Text('Done'),
          ),
        ],
      ],
    );
  }
}
