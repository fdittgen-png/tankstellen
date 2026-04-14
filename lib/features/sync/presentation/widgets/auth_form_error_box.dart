import 'package:flutter/material.dart';

/// Inline error banner used by [AuthFormWidget]. Renders a small Row
/// with a leading error icon and the supplied [message] inside a
/// rounded container tinted with the theme's error color at 10% alpha.
///
/// Pulled out of `auth_form_widget.dart` so the form's `build` method
/// drops the inline banner block and so the error styling can be
/// exercised by widget tests in isolation.
class AuthFormErrorBox extends StatelessWidget {
  final String message;

  const AuthFormErrorBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
