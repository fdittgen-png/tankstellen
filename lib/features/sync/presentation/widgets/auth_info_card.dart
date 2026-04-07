import 'package:flutter/material.dart';

/// Informational card explaining the benefits of creating an account.
///
/// Displayed below the sign-in/sign-up form for unauthenticated users.
class AuthInfoCard extends StatelessWidget {
  const AuthInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Text('Why create an account?',
                    style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• Sync favorites, alerts, and saved routes across devices\n'
              '• Prepare a route on your phone, use it in your car\n'
              '• No data is shared with third parties\n'
              '• You can delete your account at any time',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
