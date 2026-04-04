import 'package:flutter/material.dart';

import 'wizard_option_card.dart';

/// Authentication step of the sync wizard: anonymous vs email.
class WizardAuthStep extends StatelessWidget {
  final bool useEmail;
  final bool isSignUp;
  final bool testing;
  final bool connecting;
  final String? testResult;
  final bool testSuccess;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final ValueChanged<bool> onUseEmailChanged;
  final VoidCallback onToggleSignUp;
  final VoidCallback onTestConnection;
  final VoidCallback onConnect;

  const WizardAuthStep({
    super.key,
    required this.useEmail,
    required this.isSignUp,
    required this.testing,
    required this.connecting,
    required this.testResult,
    required this.testSuccess,
    required this.emailController,
    required this.passwordController,
    required this.onUseEmailChanged,
    required this.onToggleSignUp,
    required this.onTestConnection,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Choose your account type', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),

        // Anonymous
        WizardOptionCard(
          icon: Icons.person_outline,
          title: 'Anonymous',
          subtitle: 'Instant, no email needed. Data tied to this device.',
          selected: !useEmail,
          onTap: () => onUseEmailChanged(false),
        ),
        const SizedBox(height: 12),

        // Email
        WizardOptionCard(
          icon: Icons.email_outlined,
          title: 'Email Account',
          subtitle: 'Sign in from any device. Recover data if phone is lost.',
          selected: useEmail,
          onTap: () => onUseEmailChanged(true),
        ),

        if (useEmail) ...[
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              helperText: isSignUp ? 'Minimum 6 characters' : null,
            ),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onToggleSignUp,
              child: Text(isSignUp ? 'Already have an account? Sign in' : 'Create new account'),
            ),
          ),
        ],

        // Test + error display
        if (testResult != null) ...[
          const SizedBox(height: 12),
          Card(
            color: testSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(testSuccess ? Icons.check_circle : Icons.error,
                      color: testSuccess ? Colors.green : Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(testResult!, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: !testing ? onTestConnection : null,
                child: Text(testing ? 'Testing...' : 'Test Connection'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: !connecting ? onConnect : null,
                child: Text(connecting ? 'Connecting...' : 'Connect'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
