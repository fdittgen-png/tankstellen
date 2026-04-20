/// Classifies the raw text decoded from a QR code into one of a
/// small set of actionable categories for the payment-scan flow
/// (#587).
///
/// Pure function — no camera access, no launcher side-effects.
/// Callers dispatch on the [QrPaymentKind] and run the appropriate
/// handler (url_launcher for URLs, launch-intent for known payment
/// apps, fallback sheet for unknown codes).
sealed class QrPaymentTarget {
  const QrPaymentTarget();
}

/// Regular web URL — open with url_launcher.externalApplication.
class QrPaymentUrl extends QrPaymentTarget {
  final String url;
  const QrPaymentUrl(this.url);
}

/// Known payment-app deep link (payconiq://, twint://, …). Launch
/// the scheme directly; the OS resolves to the installed app.
class QrPaymentAppLink extends QrPaymentTarget {
  final String uri;
  final String schemeLabel;
  const QrPaymentAppLink({required this.uri, required this.schemeLabel});
}

/// EPC SEPA "Girocode" QR — a structured payment string parseable
/// into beneficiary + IBAN + amount. The UI can show this as a
/// confirmation prompt before a banking app takes over. See
/// https://en.wikipedia.org/wiki/EPC_QR_code
class QrPaymentEpc extends QrPaymentTarget {
  final String raw;
  final String? beneficiary;
  final String? iban;
  final double? amountEur;
  const QrPaymentEpc({
    required this.raw,
    this.beneficiary,
    this.iban,
    this.amountEur,
  });
}

/// Unrecognised content — show the raw text with a copy / report
/// button so the user can act on it manually.
class QrPaymentUnknown extends QrPaymentTarget {
  final String raw;
  const QrPaymentUnknown(this.raw);
}

abstract class QrPaymentDecoder {
  QrPaymentDecoder._();

  /// Map of known payment-app schemes to their user-facing labels.
  /// Keep lowercase — we normalise scheme on the input side.
  static const _knownSchemes = <String, String>{
    'payconiq': 'Payconiq',
    'twint': 'TWINT',
    'bizum': 'Bizum',
    'revolut': 'Revolut',
    'paypal': 'PayPal',
    'bcr': 'Bizum BCR',
    'satispay': 'Satispay',
    // #723 — regional EU payment-app schemes we see at gas stations.
    'wero': 'Wero',
    'mobilepay': 'MobilePay',
    'vipps': 'Vipps',
    'swish': 'Swish',
    'mbway': 'MB Way',
    'blik': 'Blik',
  };

  /// Classify a raw QR value. Returns one of the sealed
  /// [QrPaymentTarget] subclasses. Handles:
  /// - http(s) URLs
  /// - EPC SEPA Girocode strings (start with "BCD\n")
  /// - Custom payment-app schemes
  /// - Anything else → [QrPaymentUnknown].
  static QrPaymentTarget decode(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return QrPaymentUnknown(text);

    // EPC SEPA Girocode — 10-line structured string starting with
    // the service tag "BCD". Must be tried before URL detection
    // because some banks embed a URL in the BCD body.
    if (_looksLikeEpc(text)) return _parseEpc(text);

    // Try to parse as a URI to decide between URL and app-link.
    Uri? uri;
    try {
      uri = Uri.parse(text);
    } catch (_) {
      return QrPaymentUnknown(text);
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme.isEmpty) return QrPaymentUnknown(text);
    if (scheme == 'http' || scheme == 'https') {
      return QrPaymentUrl(text);
    }
    final label = _knownSchemes[scheme];
    if (label != null) {
      return QrPaymentAppLink(uri: text, schemeLabel: label);
    }
    return QrPaymentUnknown(text);
  }

  static bool _looksLikeEpc(String text) {
    final firstLine = text.split('\n').first.trim();
    return firstLine == 'BCD';
  }

  static QrPaymentEpc _parseEpc(String text) {
    // EPC QR fields (lines 1..10): service tag, version, encoding,
    // identification (SCT), BIC, beneficiary name, IBAN, amount
    // (EURxx.xx), purpose, remittance info. Missing lines are blank.
    final lines = text.split('\n').map((l) => l.trim()).toList();
    String? field(int idx) => lines.length > idx ? lines[idx] : null;

    double? amount;
    final amountField = field(7);
    if (amountField != null && amountField.toUpperCase().startsWith('EUR')) {
      amount = double.tryParse(amountField.substring(3).trim());
    }

    return QrPaymentEpc(
      raw: text,
      beneficiary: field(5),
      iban: field(6),
      amountEur: amount,
    );
  }
}
