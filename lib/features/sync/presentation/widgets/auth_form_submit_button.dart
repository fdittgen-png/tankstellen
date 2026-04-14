import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Submit CTA at the bottom of [AuthFormWidget]. Renders a
/// [FilledButton.icon] whose label and icon depend on the current form
/// mode (anonymous vs email, sign-up vs sign-in) and replaces the icon
/// with a spinner while [isLoading] is true.
///
/// Pulled out of `auth_form_widget.dart` so the form's `build` method
/// drops the 30-line button block and so the label/icon switching can
/// be exercised by widget tests in isolation.
class AuthFormSubmitButton extends StatelessWidget {
  final bool isLoading;
  final bool useEmail;
  final bool isSignUp;
  final VoidCallback onPressed;

  const AuthFormSubmitButton({
    super.key,
    required this.isLoading,
    required this.useEmail,
    required this.isSignUp,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(
              useEmail
                  ? (isSignUp ? Icons.person_add : Icons.login)
                  : Icons.flash_on,
            ),
      label: Text(
        isLoading
            ? (l10n?.syncConnectingButton ?? 'Connecting...')
            : useEmail
                ? (isSignUp
                    ? (l10n?.authCreateAccountAndConnect ??
                        'Create account & connect')
                    : (l10n?.authSignInAndConnect ?? 'Sign in & connect'))
                : (l10n?.authConnectAnonymously ?? 'Connect anonymously'),
      ),
    );
  }
}
