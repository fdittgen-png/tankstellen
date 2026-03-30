import 'package:flutter/material.dart';
import '../storage/hive_storage.dart';

class LocationConsentDialog {
  static const String _consentKey = 'location_consent_given';

  static bool hasConsent(HiveStorage storage) {
    return storage.getSetting(_consentKey) == true;
  }

  static Future<void> recordConsent(HiveStorage storage) async {
    await storage.putSetting(_consentKey, true);
  }

  static Future<bool> show(BuildContext context) async {
    final lang = Localizations.localeOf(context).languageCode;
    final t = _ConsentTexts(lang);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(t.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.subtitle, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(t.whatHappens),
              const SizedBox(height: 8),
              ...t.bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('  \u2022  ', style: TextStyle(fontSize: 14)),
                    Expanded(child: Text(b, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              Text(t.revoke, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Text(t.legal, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.decline),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.accept),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _ConsentTexts {
  final String lang;
  _ConsentTexts(this.lang);

  String get title => _t({
    'en': 'Location Access',
    'fr': 'Accès à la localisation',
    'de': 'Standortfreigabe',
    'es': 'Acceso a ubicación',
    'it': 'Accesso alla posizione',
    'nl': 'Locatietoegang',
    'da': 'Placeringsadgang',
    'sv': 'Platsåtkomst',
    'fi': 'Sijaintilupa',
    'pl': 'Dostęp do lokalizacji',
  });

  String get subtitle => _t({
    'en': 'This app would like to use your location to find fuel stations near you.',
    'fr': 'Cette application souhaite utiliser votre position pour trouver les stations-service près de chez vous.',
    'de': 'Diese App möchte Ihren Standort verwenden, um Tankstellen in Ihrer Nähe zu finden.',
    'es': 'Esta aplicación quiere usar tu ubicación para encontrar gasolineras cerca de ti.',
    'it': 'Questa app vorrebbe usare la tua posizione per trovare distributori vicino a te.',
    'nl': 'Deze app wil je locatie gebruiken om tankstations in de buurt te vinden.',
    'da': 'Denne app vil bruge din placering til at finde tankstationer i nærheden.',
    'sv': 'Denna app vill använda din plats för att hitta bensinstationer i närheten.',
    'fi': 'Tämä sovellus haluaa käyttää sijaintiasi löytääkseen huoltoasemia läheltäsi.',
    'pl': 'Ta aplikacja chce użyć Twojej lokalizacji, aby znaleźć stacje benzynowe w pobliżu.',
  });

  String get whatHappens => _t({
    'en': 'What happens with your location data:',
    'fr': 'Ce qui se passe avec vos données de localisation :',
    'de': 'Was passiert mit Ihren Standortdaten:',
    'es': 'Qué pasa con tus datos de ubicación:',
    'it': 'Cosa succede con i tuoi dati di posizione:',
    'nl': 'Wat er met je locatiegegevens gebeurt:',
    'da': 'Hvad der sker med dine placeringsdata:',
    'sv': 'Vad som händer med dina platsdata:',
    'fi': 'Mitä sijaintitiedoillesi tapahtuu:',
    'pl': 'Co dzieje się z danymi o Twojej lokalizacji:',
  });

  List<String> get bullets => [
    _t({
      'en': 'Your coordinates are sent to the fuel price API to find nearby stations.',
      'fr': 'Vos coordonnées sont envoyées à l\'API de prix des carburants pour trouver les stations proches.',
      'de': 'Ihre Koordinaten werden an die Kraftstoffpreis-API gesendet, um Tankstellen in der Nähe zu finden.',
      'es': 'Tus coordenadas se envían a la API de precios de combustible para encontrar gasolineras cercanas.',
      'it': 'Le tue coordinate vengono inviate all\'API prezzi carburanti per trovare le stazioni vicine.',
    }),
    _t({
      'en': 'Your location is not stored on any server — there is no server.',
      'fr': 'Votre position n\'est stockée sur aucun serveur — il n\'y a pas de serveur.',
      'de': 'Ihr Standort wird nicht auf Servern gespeichert — es gibt keine eigenen Server.',
      'es': 'Tu ubicación no se almacena en ningún servidor — no hay servidor.',
      'it': 'La tua posizione non viene memorizzata su alcun server — non c\'è un server.',
    }),
    _t({
      'en': 'Location data is not used for advertising, analytics, or tracking.',
      'fr': 'Les données de localisation ne sont pas utilisées pour la publicité, l\'analyse ou le suivi.',
      'de': 'Standortdaten werden nicht für Werbung, Analyse oder Tracking verwendet.',
      'es': 'Los datos de ubicación no se usan para publicidad, análisis ni seguimiento.',
      'it': 'I dati di posizione non vengono usati per pubblicità, analisi o tracciamento.',
    }),
  ];

  String get revoke => _t({
    'en': 'You can revoke location access anytime in system settings. Alternatively, search by postal code.',
    'fr': 'Vous pouvez révoquer l\'accès à la localisation à tout moment dans les paramètres système. Alternativement, recherchez par code postal.',
    'de': 'Sie können die Standortfreigabe jederzeit in den Systemeinstellungen widerrufen. Alternativ können Sie per Postleitzahl suchen.',
    'es': 'Puedes revocar el acceso a la ubicación en cualquier momento en los ajustes del sistema. También puedes buscar por código postal.',
    'it': 'Puoi revocare l\'accesso alla posizione in qualsiasi momento nelle impostazioni. In alternativa, cerca per CAP.',
  });

  String get legal => _t({
    'en': 'Legal basis: Art. 6(1)(a) GDPR (Consent)',
    'fr': 'Base juridique : Art. 6(1)(a) RGPD (Consentement)',
    'de': 'Rechtsgrundlage: Art. 6 Abs. 1 lit. a DSGVO (Einwilligung)',
    'es': 'Base legal: Art. 6(1)(a) RGPD (Consentimiento)',
    'it': 'Base giuridica: Art. 6(1)(a) GDPR (Consenso)',
  });

  String get decline => _t({
    'en': 'Decline', 'fr': 'Refuser', 'de': 'Ablehnen',
    'es': 'Rechazar', 'it': 'Rifiuta', 'nl': 'Weigeren',
    'da': 'Afvis', 'sv': 'Avböj', 'fi': 'Hylkää', 'pl': 'Odmów',
  });

  String get accept => _t({
    'en': 'Accept', 'fr': 'Accepter', 'de': 'Zustimmen',
    'es': 'Aceptar', 'it': 'Accetta', 'nl': 'Accepteren',
    'da': 'Acceptér', 'sv': 'Acceptera', 'fi': 'Hyväksy', 'pl': 'Akceptuj',
  });

  String _t(Map<String, String> map) => map[lang] ?? map['en'] ?? map.values.first;
}
