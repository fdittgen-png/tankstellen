import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Privacy policy', () {
    late String html;

    setUpAll(() {
      final file = File('docs/privacy-policy/index.html');
      expect(file.existsSync(), isTrue,
          reason: 'Privacy policy HTML file must exist at docs/privacy-policy/index.html');
      html = file.readAsStringSync();
    });

    test('file is non-empty HTML', () {
      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('</html>'));
    });

    test('contains required section: data collected', () {
      expect(html, contains('Data collected'));
    });

    test('contains required section: data NOT collected', () {
      expect(html, contains('Data NOT collected'));
    });

    test('contains required section: third-party services', () {
      expect(html, contains('Third-party services'));
    });

    test('contains required section: data security', () {
      expect(html, contains('Data security'));
    });

    test('contains required section: user rights', () {
      expect(html, contains('Your rights'));
    });

    test('contains required section: contact', () {
      expect(html, contains('Contact'));
      expect(html, contains('fdittgen@gmail.com'));
    });

    test('mentions location data', () {
      expect(html, contains('Location'));
    });

    test('mentions API key storage', () {
      expect(html, contains('API key'));
    });

    test('mentions TankSync as optional', () {
      expect(html, contains('TankSync'));
      expect(html, contains('optional'));
    });

    test('mentions HTTPS encryption', () {
      expect(html, contains('HTTPS'));
    });
  });
}
