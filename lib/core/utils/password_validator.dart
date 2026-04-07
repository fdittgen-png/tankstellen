/// Password complexity validation for new password creation.
///
/// Rules:
/// - Minimum 8 characters
/// - At least 1 uppercase letter
/// - At least 1 lowercase letter
/// - At least 1 digit
/// - At least 1 special character
///
/// Also provides a strength rating (weak/fair/strong) for UI feedback.
class PasswordValidator {
  const PasswordValidator._();

  static const int minLength = 8;

  static final _uppercaseRegex = RegExp(r'[A-Z]');
  static final _lowercaseRegex = RegExp(r'[a-z]');
  static final _digitRegex = RegExp(r'[0-9]');
  static final _specialRegex = RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"|,.<>/?\\`~]');

  /// Returns a list of unmet requirements for a new password.
  /// Empty list means the password meets all requirements.
  static List<PasswordRequirement> validate(String password) {
    final results = <PasswordRequirement>[];

    results.add(PasswordRequirement(
      type: PasswordRequirementType.minLength,
      met: password.length >= minLength,
    ));
    results.add(PasswordRequirement(
      type: PasswordRequirementType.uppercase,
      met: _uppercaseRegex.hasMatch(password),
    ));
    results.add(PasswordRequirement(
      type: PasswordRequirementType.lowercase,
      met: _lowercaseRegex.hasMatch(password),
    ));
    results.add(PasswordRequirement(
      type: PasswordRequirementType.digit,
      met: _digitRegex.hasMatch(password),
    ));
    results.add(PasswordRequirement(
      type: PasswordRequirementType.special,
      met: _specialRegex.hasMatch(password),
    ));

    return results;
  }

  /// Whether all requirements are met.
  static bool isValid(String password) {
    return validate(password).every((r) => r.met);
  }

  /// Returns the first unmet requirement error message, or null if valid.
  /// Uses localized strings when available, falls back to English.
  static String? getFirstError(String password) {
    final requirements = validate(password);
    for (final req in requirements) {
      if (!req.met) return req.type.fallbackMessage;
    }
    return null;
  }

  /// Calculate password strength as a ratio from 0.0 to 1.0.
  static double strengthScore(String password) {
    if (password.isEmpty) return 0.0;
    final requirements = validate(password);
    final metCount = requirements.where((r) => r.met).length;
    // Base score from requirements (0-5 -> 0.0-0.8)
    var score = metCount / requirements.length * 0.8;
    // Bonus for length beyond minimum (up to 0.2 extra)
    if (password.length > minLength) {
      final extra = (password.length - minLength).clamp(0, 8);
      score += extra / 8 * 0.2;
    }
    return score.clamp(0.0, 1.0);
  }

  /// Returns the strength level based on score.
  static PasswordStrength strength(String password) {
    final score = strengthScore(password);
    if (score < 0.4) return PasswordStrength.weak;
    if (score < 0.7) return PasswordStrength.fair;
    return PasswordStrength.strong;
  }
}

/// A single password requirement and whether it is met.
class PasswordRequirement {
  final PasswordRequirementType type;
  final bool met;

  const PasswordRequirement({required this.type, required this.met});
}

/// Types of password requirements.
enum PasswordRequirementType {
  minLength,
  uppercase,
  lowercase,
  digit,
  special;

  /// English fallback message for this requirement.
  String get fallbackMessage {
    switch (this) {
      case PasswordRequirementType.minLength:
        return 'At least ${PasswordValidator.minLength} characters';
      case PasswordRequirementType.uppercase:
        return 'At least 1 uppercase letter';
      case PasswordRequirementType.lowercase:
        return 'At least 1 lowercase letter';
      case PasswordRequirementType.digit:
        return 'At least 1 number';
      case PasswordRequirementType.special:
        return 'At least 1 special character';
    }
  }
}

/// Password strength level.
enum PasswordStrength {
  weak,
  fair,
  strong;
}
