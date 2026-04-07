import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/password_validator.dart';

void main() {
  group('PasswordValidator', () {
    group('isValid', () {
      test('rejects empty password', () {
        expect(PasswordValidator.isValid(''), false);
      });

      test('rejects short password even with all character types', () {
        expect(PasswordValidator.isValid('Ab1!'), false);
      });

      test('rejects password without uppercase', () {
        expect(PasswordValidator.isValid('abcdefg1!'), false);
      });

      test('rejects password without lowercase', () {
        expect(PasswordValidator.isValid('ABCDEFG1!'), false);
      });

      test('rejects password without digit', () {
        expect(PasswordValidator.isValid('Abcdefgh!'), false);
      });

      test('rejects password without special character', () {
        expect(PasswordValidator.isValid('Abcdefg1'), false);
      });

      test('accepts valid password meeting all requirements', () {
        expect(PasswordValidator.isValid('Abcdefg1!'), true);
      });

      test('accepts long complex password', () {
        expect(PasswordValidator.isValid('MyP@ssw0rd!Strong'), true);
      });

      test('rejects all-lowercase password', () {
        expect(PasswordValidator.isValid('abcdefghij'), false);
      });

      test('rejects all-uppercase password', () {
        expect(PasswordValidator.isValid('ABCDEFGHIJ'), false);
      });

      test('rejects all-digits password', () {
        expect(PasswordValidator.isValid('1234567890'), false);
      });

      test('rejects all-special password', () {
        expect(PasswordValidator.isValid('!@#\$%^&*()'), false);
      });
    });

    group('validate', () {
      test('returns 5 requirements', () {
        final results = PasswordValidator.validate('test');
        expect(results.length, 5);
      });

      test('all requirements met for valid password', () {
        final results = PasswordValidator.validate('Abcdefg1!');
        expect(results.every((r) => r.met), true);
      });

      test('only minLength unmet for short but complex password', () {
        final results = PasswordValidator.validate('Ab1!');
        final unmet = results.where((r) => !r.met).toList();
        expect(unmet.length, 1);
        expect(unmet.first.type, PasswordRequirementType.minLength);
      });

      test('multiple unmet for simple password', () {
        final results = PasswordValidator.validate('abc');
        final unmet = results.where((r) => !r.met).toList();
        expect(unmet.length, greaterThanOrEqualTo(3));
      });

      test('identifies which requirements are met', () {
        final results = PasswordValidator.validate('abcdefgh');
        final byType = {for (final r in results) r.type: r.met};
        expect(byType[PasswordRequirementType.minLength], true);
        expect(byType[PasswordRequirementType.lowercase], true);
        expect(byType[PasswordRequirementType.uppercase], false);
        expect(byType[PasswordRequirementType.digit], false);
        expect(byType[PasswordRequirementType.special], false);
      });
    });

    group('getFirstError', () {
      test('returns null for valid password', () {
        expect(PasswordValidator.getFirstError('Abcdefg1!'), isNull);
      });

      test('returns error string for invalid password', () {
        expect(PasswordValidator.getFirstError('abc'), isNotNull);
      });

      test('returns minLength error first for short password', () {
        final error = PasswordValidator.getFirstError('a');
        expect(error, contains('8'));
      });
    });

    group('strengthScore', () {
      test('returns 0.0 for empty password', () {
        expect(PasswordValidator.strengthScore(''), 0.0);
      });

      test('returns low score for weak password', () {
        final score = PasswordValidator.strengthScore('abc');
        expect(score, lessThan(0.4));
      });

      test('returns higher score for better password', () {
        final weak = PasswordValidator.strengthScore('abc');
        final strong = PasswordValidator.strengthScore('Abcdefg1!');
        expect(strong, greaterThan(weak));
      });

      test('returns max 1.0', () {
        final score = PasswordValidator.strengthScore('MyV3ryStr0ng!P@sswooooooooord');
        expect(score, lessThanOrEqualTo(1.0));
      });

      test('bonus score for length beyond minimum', () {
        final base = PasswordValidator.strengthScore('Abcdefg1!'); // 9 chars
        final longer = PasswordValidator.strengthScore('Abcdefg1!extra'); // 14 chars
        expect(longer, greaterThan(base));
      });
    });

    group('strength', () {
      test('returns weak for simple password', () {
        expect(PasswordValidator.strength('abc'), PasswordStrength.weak);
      });

      test('returns fair for medium password', () {
        // Meets 3 of 5: minLength, lowercase, uppercase -> score ~0.48
        expect(PasswordValidator.strength('Abcdefgh'), PasswordStrength.fair);
      });

      test('returns strong for complex password', () {
        expect(PasswordValidator.strength('Abcdefg1!'), PasswordStrength.strong);
      });

      test('returns weak for empty password', () {
        expect(PasswordValidator.strength(''), PasswordStrength.weak);
      });
    });

    group('PasswordRequirementType', () {
      test('all types have fallback messages', () {
        for (final type in PasswordRequirementType.values) {
          expect(type.fallbackMessage, isNotEmpty);
        }
      });

      test('minLength message contains the minimum length', () {
        expect(
          PasswordRequirementType.minLength.fallbackMessage,
          contains('${PasswordValidator.minLength}'),
        );
      });
    });

    group('edge cases', () {
      test('handles unicode characters', () {
        // Unicode letters do not count as ASCII uppercase/lowercase
        expect(PasswordValidator.isValid('Passwort1!'), true);
      });

      test('recognizes various special characters', () {
        const specials = ['!', '@', '#', '\$', '%', '^', '&', '*', '(', ')', '-', '_', '+', '='];
        for (final s in specials) {
          final password = 'Abcdefg1$s';
          expect(PasswordValidator.isValid(password), true, reason: 'Should accept "$s" as special char');
        }
      });

      test('exactly minimum length with all requirements met', () {
        expect(PasswordValidator.isValid('Abcde1!x'), true); // exactly 8 chars
      });

      test('one char below minimum length with all types', () {
        expect(PasswordValidator.isValid('Abcd1!x'), false); // 7 chars
      });
    });
  });
}
