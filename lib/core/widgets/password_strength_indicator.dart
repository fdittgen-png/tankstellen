import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/password_validator.dart';

/// Visual password strength indicator with real-time requirement checklist.
///
/// Shows:
/// - A colored progress bar (red/orange/green)
/// - Strength label (Weak/Fair/Strong)
/// - Individual requirement checks with icons
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final strength = PasswordValidator.strength(password);
    final score = PasswordValidator.strengthScore(password);
    final requirements = PasswordValidator.validate(password);

    final color = switch (strength) {
      PasswordStrength.weak => Colors.red,
      PasswordStrength.fair => Colors.orange,
      PasswordStrength.strong => Colors.green,
    };

    final label = switch (strength) {
      PasswordStrength.weak => l10n?.passwordStrengthWeak ?? 'Weak',
      PasswordStrength.fair => l10n?.passwordStrengthFair ?? 'Fair',
      PasswordStrength.strong => l10n?.passwordStrengthStrong ?? 'Strong',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Strength bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: color,
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Requirements checklist
        ...requirements.map((req) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Icon(
                req.met ? Icons.check_circle : Icons.circle_outlined,
                size: 14,
                color: req.met ? Colors.green : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                _requirementLabel(l10n, req.type),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: req.met
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  String _requirementLabel(AppLocalizations? l10n, PasswordRequirementType type) {
    switch (type) {
      case PasswordRequirementType.minLength:
        return l10n?.passwordReqMinLength ?? 'At least ${PasswordValidator.minLength} characters';
      case PasswordRequirementType.uppercase:
        return l10n?.passwordReqUppercase ?? 'At least 1 uppercase letter';
      case PasswordRequirementType.lowercase:
        return l10n?.passwordReqLowercase ?? 'At least 1 lowercase letter';
      case PasswordRequirementType.digit:
        return l10n?.passwordReqDigit ?? 'At least 1 number';
      case PasswordRequirementType.special:
        return l10n?.passwordReqSpecial ?? 'At least 1 special character';
    }
  }
}
