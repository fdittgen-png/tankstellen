#!/usr/bin/env python3
"""Generate Sparkilo's localized privacy policy pages.

Input: the TRANSLATIONS dict below (one entry per locale, holding every
piece of human-readable text the page needs).
Output: docs/privacy-policy/<locale>/index.html for non-English locales,
and docs/privacy-policy/index.html for the canonical English version.

The same HTML structure is shared across locales so adding or editing a
section is one place to change. Re-run after editing TRANSLATIONS:

    python3 tools/build_privacy_policy.py

Then commit the generated files. GitHub Pages picks them up on the next
master push under the docs/ directory.

App Store Connect accepts one URL per locale. The locale subdirectories
correspond directly to the ASC locale codes you'd paste into the App
Privacy form (en-GB and en-AU reuse the canonical en URL because the
text is identical; Apple is fine with that).
"""
from __future__ import annotations

import html
import os
import textwrap
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
OUT_ROOT = REPO_ROOT / "docs" / "privacy-policy"
LAST_UPDATED_ISO = "2026-05-09"

# Locale → relative URL path used in the language switcher.
LOCALE_URLS = {
    "en":  "../",
    "de":  "../de/",
    "fr":  "../fr/",
    "es":  "../es/",
    "it":  "../it/",
    "nl":  "../nl/",
    "pt":  "../pt/",
    "sv":  "../sv/",
    "fi":  "../fi/",
    "da":  "../da/",
    "pl":  "../pl/",
    "sl":  "../sl/",
    "ko":  "../ko/",
}

# Display labels for each locale, in the locale's own language.
LOCALE_LABELS = {
    "en": "English",
    "de": "Deutsch",
    "fr": "Français",
    "es": "Español",
    "it": "Italiano",
    "nl": "Nederlands",
    "pt": "Português",
    "sv": "Svenska",
    "fi": "Suomi",
    "da": "Dansk",
    "pl": "Polski",
    "sl": "Slovenščina",
    "ko": "한국어",
}

# Per-locale translations. Keys must stay aligned across locales.
TRANSLATIONS = {
    "en": {
        "html_lang": "en",
        "page_title": "Sparkilo — Privacy Policy",
        "h1": "Privacy Policy",
        "meta_app": "Sparkilo (de.tankstellen.tankstellen on iOS, de.tankstellen.fuelprices on Android)",
        "meta_last_updated": "Last updated: 9 May 2026",
        "h2_overview": "1. Overview",
        "p_overview": (
            "Sparkilo (formerly known as Fuel Prices Europe & More) is a free, open-source fuel and "
            "EV charging price comparison app. It is built around a <strong>local-first, "
            "privacy-respecting</strong> architecture. There are no ads, no tracking pixels, and no "
            "advertising identifiers."
        ),
        "h2_collected": "2. Data we use",
        "h3_location": "2.1 Approximate location",
        "p_location": (
            "When you grant location permission, the app reads your approximate position to find nearby "
            "fuel and charging stations. Coordinates are sent to third-party price APIs (see Section 4) "
            "as part of the search query. Your location is <strong>not stored on any server we operate</strong> "
            "and is never used for tracking or profiling."
        ),
        "h3_apikey": "2.2 API keys you provide",
        "p_apikey": (
            "If you provide your own API key (e.g. for Tankerkönig), it is stored locally in encrypted "
            "secure storage (Android Keystore / iOS Keychain). The key is sent only to the corresponding "
            "API provider and never to us or any other party."
        ),
        "h3_local": "2.3 Favorites, profiles and settings",
        "p_local": (
            "Your favorites, search profiles, fuel preferences and app settings are stored locally on "
            "your device using Hive, an embedded local database."
        ),
        "h3_sync": "2.4 TankSync (optional cloud sync)",
        "p_sync_intro": "If you opt in to TankSync, an anonymous account is created via Supabase. The data synced is:",
        "li_sync_id": "Anonymous user identifier (a UUID — no email or name)",
        "li_sync_fav": "Favorite station IDs",
        "li_sync_alerts": "Price alert configurations",
        "li_sync_reports": "Community price reports (station ID, fuel type, price, timestamp)",
        "p_sync_outro": (
            "TankSync is optional and disabled by default. You can view, export and delete all "
            "server-side data from the Data Transparency screen inside the app."
        ),
        "h3_diagnostic": "2.5 Crash and diagnostic reports (opt-in)",
        "p_diagnostic": (
            "If you enable diagnostic reporting in Settings, anonymous crash reports and performance "
            "traces are sent to Sentry. No personally identifying information, location or content is "
            "included. Diagnostic reporting is off by default."
        ),
        "h2_not_collected": "3. Data we do NOT collect",
        "li_nc_email": "Name, email address or phone number",
        "li_nc_payment": "Financial or payment information",
        "li_nc_health": "Health or fitness data",
        "li_nc_contacts": "Contacts, messages or call logs",
        "li_nc_photos": "Photos, videos or files (camera and photo library access is only used for receipt scanning when you initiate it)",
        "li_nc_history": "Browsing history",
        "li_nc_adid": "Device advertising identifiers",
        "h2_third_parties": "4. Third-party services",
        "p_third_parties_intro": "The app communicates with the following third-party APIs:",
        "li_tk": "<strong>Tankerkönig</strong> (creativecommons.tankerkoenig.de) — German fuel prices. Receives: search coordinates, your API key.",
        "li_pc": "<strong>Prix Carburants</strong> (data.economie.gouv.fr) — French fuel prices. Receives: search coordinates.",
        "li_it": "<strong>Italian fuel-price API</strong> (osservaprezzi.mise.gov.it) — Italian fuel prices. Receives: search coordinates.",
        "li_es": "<strong>Spanish fuel-price API</strong> (sedeaplicaciones.minetur.gob.es) — Spanish fuel prices. Receives: search coordinates.",
        "li_at": "<strong>Spritpreisrechner</strong> (spritpreisrechner.at) — Austrian fuel prices. Receives: search coordinates.",
        "li_be": "<strong>FuelWatch</strong> (fuelwatch.be) — Belgian fuel prices. Receives: search coordinates.",
        "li_lu": "<strong>data.public.lu</strong> — Luxembourg fuel prices. Receives: search coordinates.",
        "li_ocm": "<strong>OpenChargeMap</strong> (api.openchargemap.io) — EV charging stations. Receives: search coordinates.",
        "li_nominatim": "<strong>Nominatim / OpenStreetMap</strong> (nominatim.openstreetmap.org) — geocoding. Receives: search text or coordinates.",
        "li_osm": "<strong>OpenStreetMap tile servers</strong> (tile.openstreetmap.org) — map tiles. Receives: tile coordinates.",
        "li_supabase": "<strong>Supabase</strong> (only if TankSync is enabled) — cloud sync backend.",
        "li_sentry": "<strong>Sentry</strong> (only if diagnostic reporting is enabled) — anonymous crash and performance reports.",
        "p_third_parties_outro": (
            "Each provider has its own privacy policy. We encourage you to review them. The app does "
            "not share data between these providers."
        ),
        "h2_security": "5. Data security",
        "li_sec_https": "All network communication uses HTTPS (TLS in transit).",
        "li_sec_keystore": "API keys are stored in platform-native encrypted storage (Android Keystore / iOS Keychain).",
        "li_sec_local": "Local data is stored on your device using Hive.",
        "li_sec_silent": "No data is sent to any server unless you initiate a search or enable TankSync / diagnostics.",
        "h2_rights": "6. Your rights",
        "p_rights_intro": "You have the right to:",
        "li_r_access": "<strong>Access</strong> — view all locally stored data in the app's Storage section.",
        "li_r_export": "<strong>Export</strong> — export your TankSync data as JSON from the Data Transparency screen.",
        "li_r_delete": "<strong>Delete</strong> — delete all local data via Settings → Delete all data; delete all server data via TankSync → Data Transparency → Delete everything.",
        "li_r_withdraw": "<strong>Withdraw consent</strong> — revoke location permission in your device settings, or disable TankSync / diagnostics, at any time.",
        "h2_children": "7. Children's privacy",
        "p_children": (
            "The app is not directed at children under 13. We do not knowingly collect personal "
            "information from children."
        ),
        "h2_changes": "8. Changes to this policy",
        "p_changes": (
            "We may update this policy from time to time. Changes will be published at this URL with "
            "an updated date. Continued use of the app constitutes acceptance of the updated policy."
        ),
        "h2_contact": "9. Contact",
        "contact_dev_label": "Developer",
        "contact_email_label": "Email",
        "contact_source_label": "Source code",
        "lang_switcher_label": "Available languages:",
    },
    # German
    "de": {
        "html_lang": "de",
        "page_title": "Sparkilo — Datenschutzerklärung",
        "h1": "Datenschutzerklärung",
        "meta_app": "Sparkilo (de.tankstellen.tankstellen unter iOS, de.tankstellen.fuelprices unter Android)",
        "meta_last_updated": "Stand: 9. Mai 2026",
        "h2_overview": "1. Überblick",
        "p_overview": (
            "Sparkilo (vormals Fuel Prices Europe & More) ist eine kostenlose, quelloffene App zum "
            "Vergleich von Kraftstoff- und Ladestationspreisen. Die App basiert auf einer "
            "<strong>local-first, datenschutzfreundlichen</strong> Architektur. Es gibt keine Werbung, "
            "kein Tracking und keine Werbe-IDs."
        ),
        "h2_collected": "2. Verwendete Daten",
        "h3_location": "2.1 Ungefährer Standort",
        "p_location": (
            "Wenn Sie den Standortzugriff erlauben, liest die App Ihre ungefähre Position aus, um "
            "nahegelegene Tankstellen und Ladesäulen zu finden. Die Koordinaten werden als Teil der "
            "Suchanfrage an Drittanbieter-APIs gesendet (siehe Abschnitt 4). Ihr Standort wird "
            "<strong>auf keinem von uns betriebenen Server gespeichert</strong> und niemals zum "
            "Tracking oder Profiling verwendet."
        ),
        "h3_apikey": "2.2 Eigene API-Schlüssel",
        "p_apikey": (
            "Wenn Sie einen eigenen API-Schlüssel hinterlegen (z. B. für Tankerkönig), wird er lokal "
            "in einem verschlüsselten Speicher (Android Keystore / iOS Keychain) gehalten. Der "
            "Schlüssel wird ausschließlich an den jeweiligen API-Anbieter gesendet, niemals an uns "
            "oder Dritte."
        ),
        "h3_local": "2.3 Favoriten, Profile und Einstellungen",
        "p_local": (
            "Ihre Favoriten, Suchprofile, Kraftstoffvorlieben und App-Einstellungen werden lokal "
            "auf Ihrem Gerät in Hive (eingebettete lokale Datenbank) gespeichert."
        ),
        "h3_sync": "2.4 TankSync (optionale Cloud-Synchronisation)",
        "p_sync_intro": "Wenn Sie TankSync aktivieren, wird über Supabase ein anonymes Konto angelegt. Synchronisiert werden:",
        "li_sync_id": "Anonyme Benutzer-ID (UUID — keine E-Mail-Adresse, kein Name)",
        "li_sync_fav": "Favoriten-Stationen-IDs",
        "li_sync_alerts": "Konfigurationen für Preisalarme",
        "li_sync_reports": "Community-Preismeldungen (Stations-ID, Kraftstoffart, Preis, Zeitstempel)",
        "p_sync_outro": (
            "TankSync ist optional und standardmäßig deaktiviert. Sie können sämtliche serverseitigen "
            "Daten im Bildschirm „Datentransparenz“ in der App einsehen, exportieren und löschen."
        ),
        "h3_diagnostic": "2.5 Absturz- und Diagnoseberichte (Opt-in)",
        "p_diagnostic": (
            "Wenn Sie die Diagnoseberichte in den Einstellungen aktivieren, werden anonyme "
            "Absturzberichte und Performance-Traces an Sentry gesendet. Es werden keine personen­"
            "bezogenen Daten, Standortdaten oder Inhalte übermittelt. Diagnoseberichte sind "
            "standardmäßig deaktiviert."
        ),
        "h2_not_collected": "3. Daten, die wir NICHT erheben",
        "li_nc_email": "Name, E-Mail-Adresse oder Telefonnummer",
        "li_nc_payment": "Finanz- oder Zahlungsdaten",
        "li_nc_health": "Gesundheits- oder Fitnessdaten",
        "li_nc_contacts": "Kontakte, Nachrichten oder Anrufprotokolle",
        "li_nc_photos": "Fotos, Videos oder Dateien (Kamera- und Fotomediathek-Zugriff wird nur für das Scannen von Belegen genutzt, wenn Sie es selbst auslösen)",
        "li_nc_history": "Browserverlauf",
        "li_nc_adid": "Werbe-IDs des Geräts",
        "h2_third_parties": "4. Drittanbieter-Dienste",
        "p_third_parties_intro": "Die App kommuniziert mit folgenden Drittanbieter-APIs:",
        "li_tk": "<strong>Tankerkönig</strong> (creativecommons.tankerkoenig.de) — deutsche Spritpreise. Empfängt: Suchkoordinaten, Ihren API-Schlüssel.",
        "li_pc": "<strong>Prix Carburants</strong> (data.economie.gouv.fr) — französische Spritpreise. Empfängt: Suchkoordinaten.",
        "li_it": "<strong>Italienische Spritpreis-API</strong> (osservaprezzi.mise.gov.it) — italienische Spritpreise. Empfängt: Suchkoordinaten.",
        "li_es": "<strong>Spanische Spritpreis-API</strong> (sedeaplicaciones.minetur.gob.es) — spanische Spritpreise. Empfängt: Suchkoordinaten.",
        "li_at": "<strong>Spritpreisrechner</strong> (spritpreisrechner.at) — österreichische Spritpreise. Empfängt: Suchkoordinaten.",
        "li_be": "<strong>FuelWatch</strong> (fuelwatch.be) — belgische Spritpreise. Empfängt: Suchkoordinaten.",
        "li_lu": "<strong>data.public.lu</strong> — luxemburgische Spritpreise. Empfängt: Suchkoordinaten.",
        "li_ocm": "<strong>OpenChargeMap</strong> (api.openchargemap.io) — Ladestationen für E-Fahrzeuge. Empfängt: Suchkoordinaten.",
        "li_nominatim": "<strong>Nominatim / OpenStreetMap</strong> (nominatim.openstreetmap.org) — Geokodierung. Empfängt: Suchtext oder Koordinaten.",
        "li_osm": "<strong>OpenStreetMap-Kachelserver</strong> (tile.openstreetmap.org) — Kartenkacheln. Empfängt: Kachelkoordinaten.",
        "li_supabase": "<strong>Supabase</strong> (nur bei aktivem TankSync) — Cloud-Synchronisations-Backend.",
        "li_sentry": "<strong>Sentry</strong> (nur bei aktiven Diagnoseberichten) — anonyme Absturz- und Performance-Berichte.",
        "p_third_parties_outro": (
            "Jeder Anbieter hat eine eigene Datenschutzerklärung. Wir empfehlen, sie zu lesen. Die "
            "App tauscht keine Daten zwischen diesen Anbietern aus."
        ),
        "h2_security": "5. Datensicherheit",
        "li_sec_https": "Alle Netzwerkkommunikation läuft über HTTPS (TLS während der Übertragung).",
        "li_sec_keystore": "API-Schlüssel werden im plattform-eigenen verschlüsselten Speicher abgelegt (Android Keystore / iOS Keychain).",
        "li_sec_local": "Lokale Daten werden auf Ihrem Gerät in Hive gespeichert.",
        "li_sec_silent": "Es werden keine Daten an Server gesendet, solange Sie nicht selbst eine Suche starten oder TankSync / Diagnose aktivieren.",
        "h2_rights": "6. Ihre Rechte",
        "p_rights_intro": "Sie haben das Recht auf:",
        "li_r_access": "<strong>Auskunft</strong> — Sie können alle lokal gespeicherten Daten im Bereich „Speicher“ der App einsehen.",
        "li_r_export": "<strong>Export</strong> — Sie können Ihre TankSync-Daten im Bildschirm „Datentransparenz“ als JSON exportieren.",
        "li_r_delete": "<strong>Löschung</strong> — alle lokalen Daten über Einstellungen → Alle Daten löschen; alle Serverdaten über TankSync → Datentransparenz → Alles löschen.",
        "li_r_withdraw": "<strong>Widerruf</strong> — Sie können den Standortzugriff in den Geräteeinstellungen jederzeit widerrufen oder TankSync / Diagnose jederzeit deaktivieren.",
        "h2_children": "7. Datenschutz für Kinder",
        "p_children": (
            "Die App richtet sich nicht an Kinder unter 13 Jahren. Wir erheben wissentlich keine "
            "personenbezogenen Daten von Kindern."
        ),
        "h2_changes": "8. Änderungen dieser Erklärung",
        "p_changes": (
            "Wir können diese Datenschutzerklärung von Zeit zu Zeit aktualisieren. Änderungen werden "
            "unter dieser URL mit aktualisiertem Datum veröffentlicht. Die fortgesetzte Nutzung der "
            "App gilt als Zustimmung zur aktualisierten Fassung."
        ),
        "h2_contact": "9. Kontakt",
        "contact_dev_label": "Entwickler",
        "contact_email_label": "E-Mail",
        "contact_source_label": "Quellcode",
        "lang_switcher_label": "Verfügbare Sprachen:",
    },
    # French
    "fr": {
        "html_lang": "fr",
        "page_title": "Sparkilo — Politique de confidentialité",
        "h1": "Politique de confidentialité",
        "meta_app": "Sparkilo (de.tankstellen.tankstellen sous iOS, de.tankstellen.fuelprices sous Android)",
        "meta_last_updated": "Dernière mise à jour : 9 mai 2026",
        "h2_overview": "1. Aperçu",
        "p_overview": (
            "Sparkilo (anciennement Fuel Prices Europe & More) est une application open-source et "
            "gratuite de comparaison de prix du carburant et des bornes de recharge. Elle est "
            "conçue selon une architecture <strong>locale d'abord et respectueuse de la vie privée</strong>. "
            "Pas de publicité, pas de pixels de suivi, pas d'identifiants publicitaires."
        ),
        "h2_collected": "2. Données utilisées",
        "h3_location": "2.1 Position approximative",
        "p_location": (
            "Lorsque vous accordez l'autorisation de localisation, l'app lit votre position "
            "approximative pour trouver les stations à proximité. Les coordonnées sont envoyées aux "
            "API tierces (voir section 4) dans le cadre de la requête. Votre position "
            "<strong>n'est stockée sur aucun serveur que nous exploitons</strong> et n'est jamais "
            "utilisée à des fins de suivi ou de profilage."
        ),
        "h3_apikey": "2.2 Clés d'API que vous fournissez",
        "p_apikey": (
            "Si vous fournissez votre propre clé d'API (par ex. Tankerkönig), elle est stockée "
            "localement dans un coffre chiffré (Android Keystore / iOS Keychain). Elle n'est "
            "envoyée qu'au fournisseur d'API correspondant, jamais à nous ni à un tiers."
        ),
        "h3_local": "2.3 Favoris, profils et paramètres",
        "p_local": (
            "Vos favoris, profils de recherche, préférences de carburant et paramètres sont "
            "stockés localement sur votre appareil via Hive, une base de données embarquée."
        ),
        "h3_sync": "2.4 TankSync (synchronisation cloud optionnelle)",
        "p_sync_intro": "Si vous activez TankSync, un compte anonyme est créé via Supabase. Les données synchronisées sont :",
        "li_sync_id": "Identifiant utilisateur anonyme (UUID — sans e-mail ni nom)",
        "li_sync_fav": "Identifiants des stations favorites",
        "li_sync_alerts": "Configurations d'alertes de prix",
        "li_sync_reports": "Signalements communautaires de prix (ID de station, type de carburant, prix, horodatage)",
        "p_sync_outro": (
            "TankSync est optionnel et désactivé par défaut. Vous pouvez consulter, exporter et "
            "supprimer toutes les données côté serveur depuis l'écran « Transparence des données » "
            "dans l'app."
        ),
        "h3_diagnostic": "2.5 Rapports d'incident et diagnostics (opt-in)",
        "p_diagnostic": (
            "Si vous activez les diagnostics dans les paramètres, des rapports d'incident anonymes "
            "et des traces de performance sont envoyés à Sentry. Aucune information personnelle, "
            "position ou contenu n'est transmis. Les diagnostics sont désactivés par défaut."
        ),
        "h2_not_collected": "3. Données NON collectées",
        "li_nc_email": "Nom, adresse e-mail ou numéro de téléphone",
        "li_nc_payment": "Informations financières ou de paiement",
        "li_nc_health": "Données de santé ou de fitness",
        "li_nc_contacts": "Contacts, messages ou journaux d'appels",
        "li_nc_photos": "Photos, vidéos ou fichiers (l'accès à l'appareil photo et à la photothèque sert uniquement à scanner des reçus à votre initiative)",
        "li_nc_history": "Historique de navigation",
        "li_nc_adid": "Identifiants publicitaires de l'appareil",
        "h2_third_parties": "4. Services tiers",
        "p_third_parties_intro": "L'app communique avec les API tierces suivantes :",
        "li_tk": "<strong>Tankerkönig</strong> (creativecommons.tankerkoenig.de) — prix allemands. Reçoit : coordonnées de recherche, votre clé d'API.",
        "li_pc": "<strong>Prix Carburants</strong> (data.economie.gouv.fr) — prix français. Reçoit : coordonnées de recherche.",
        "li_it": "<strong>API italienne des prix</strong> (osservaprezzi.mise.gov.it) — prix italiens. Reçoit : coordonnées de recherche.",
        "li_es": "<strong>API espagnole des prix</strong> (sedeaplicaciones.minetur.gob.es) — prix espagnols. Reçoit : coordonnées de recherche.",
        "li_at": "<strong>Spritpreisrechner</strong> (spritpreisrechner.at) — prix autrichiens. Reçoit : coordonnées de recherche.",
        "li_be": "<strong>FuelWatch</strong> (fuelwatch.be) — prix belges. Reçoit : coordonnées de recherche.",
        "li_lu": "<strong>data.public.lu</strong> — prix luxembourgeois. Reçoit : coordonnées de recherche.",
        "li_ocm": "<strong>OpenChargeMap</strong> (api.openchargemap.io) — bornes de recharge. Reçoit : coordonnées de recherche.",
        "li_nominatim": "<strong>Nominatim / OpenStreetMap</strong> (nominatim.openstreetmap.org) — géocodage. Reçoit : texte ou coordonnées de recherche.",
        "li_osm": "<strong>Serveurs de tuiles OpenStreetMap</strong> (tile.openstreetmap.org) — fonds de carte. Reçoit : coordonnées de tuile.",
        "li_supabase": "<strong>Supabase</strong> (uniquement si TankSync est activé) — backend de synchronisation cloud.",
        "li_sentry": "<strong>Sentry</strong> (uniquement si les diagnostics sont activés) — rapports anonymes d'incidents et de performance.",
        "p_third_parties_outro": (
            "Chaque fournisseur dispose de sa propre politique de confidentialité. Nous vous "
            "encourageons à les consulter. L'app ne partage pas de données entre ces fournisseurs."
        ),
        "h2_security": "5. Sécurité des données",
        "li_sec_https": "Toutes les communications réseau utilisent HTTPS (chiffrement TLS en transit).",
        "li_sec_keystore": "Les clés d'API sont stockées dans le coffre chiffré natif de la plateforme (Android Keystore / iOS Keychain).",
        "li_sec_local": "Les données locales sont stockées sur votre appareil via Hive.",
        "li_sec_silent": "Aucune donnée n'est envoyée à un serveur tant que vous n'initiez pas une recherche ou n'activez pas TankSync / les diagnostics.",
        "h2_rights": "6. Vos droits",
        "p_rights_intro": "Vous avez le droit de :",
        "li_r_access": "<strong>Accès</strong> — consulter toutes les données stockées localement dans la section Stockage de l'app.",
        "li_r_export": "<strong>Export</strong> — exporter vos données TankSync au format JSON depuis l'écran Transparence des données.",
        "li_r_delete": "<strong>Suppression</strong> — supprimer toutes les données locales via Réglages → Tout supprimer ; supprimer toutes les données serveur via TankSync → Transparence des données → Tout supprimer.",
        "li_r_withdraw": "<strong>Retrait du consentement</strong> — révoquer l'autorisation de localisation dans les réglages système ou désactiver TankSync / les diagnostics à tout moment.",
        "h2_children": "7. Confidentialité des enfants",
        "p_children": (
            "L'application ne s'adresse pas aux enfants de moins de 13 ans. Nous ne collectons "
            "pas sciemment d'informations personnelles auprès d'enfants."
        ),
        "h2_changes": "8. Modifications de cette politique",
        "p_changes": (
            "Cette politique peut être mise à jour de temps à autre. Les modifications seront "
            "publiées à cette URL avec une date mise à jour. L'utilisation continue de l'application "
            "vaut acceptation de la version mise à jour."
        ),
        "h2_contact": "9. Contact",
        "contact_dev_label": "Développeur",
        "contact_email_label": "E-mail",
        "contact_source_label": "Code source",
        "lang_switcher_label": "Langues disponibles :",
    },
    # Spanish
    "es": {
        "html_lang": "es",
        "page_title": "Sparkilo — Política de privacidad",
        "h1": "Política de privacidad",
        "meta_app": "Sparkilo (de.tankstellen.tankstellen en iOS, de.tankstellen.fuelprices en Android)",
        "meta_last_updated": "Última actualización: 9 de mayo de 2026",
        "h2_overview": "1. Resumen",
        "p_overview": (
            "Sparkilo (antes Fuel Prices Europe & More) es una aplicación gratuita y de código "
            "abierto para comparar precios de carburante y de puntos de recarga eléctrica. Está "
            "diseñada con una arquitectura <strong>local-first y respetuosa con la privacidad</strong>. "
            "Sin anuncios, sin píxeles de seguimiento, sin identificadores publicitarios."
        ),
        "h2_collected": "2. Datos que utilizamos",
        "h3_location": "2.1 Ubicación aproximada",
        "p_location": (
            "Cuando concede el permiso de ubicación, la app lee su posición aproximada para "
            "encontrar gasolineras y puntos de recarga cercanos. Las coordenadas se envían a "
            "APIs de terceros (ver sección 4) como parte de la consulta. Su ubicación "
            "<strong>no se almacena en ningún servidor que operemos</strong> y nunca se utiliza "
            "para seguimiento o perfilado."
        ),
        "h3_apikey": "2.2 Claves de API que usted proporciona",
        "p_apikey": (
            "Si proporciona su propia clave de API (por ejemplo de Tankerkönig), se almacena "
            "localmente en almacenamiento cifrado (Android Keystore / iOS Keychain). La clave "
            "se envía únicamente al proveedor correspondiente, nunca a nosotros ni a terceros."
        ),
        "h3_local": "2.3 Favoritos, perfiles y ajustes",
        "p_local": (
            "Sus favoritos, perfiles de búsqueda, preferencias de combustible y ajustes se "
            "almacenan localmente en su dispositivo mediante Hive, una base de datos local embebida."
        ),
        "h3_sync": "2.4 TankSync (sincronización en la nube opcional)",
        "p_sync_intro": "Si activa TankSync, se crea una cuenta anónima en Supabase. Los datos sincronizados son:",
        "li_sync_id": "Identificador anónimo de usuario (UUID — sin correo ni nombre)",
        "li_sync_fav": "IDs de gasolineras favoritas",
        "li_sync_alerts": "Configuraciones de alertas de precio",
        "li_sync_reports": "Reportes comunitarios de precios (ID de gasolinera, tipo de combustible, precio, marca temporal)",
        "p_sync_outro": (
            "TankSync es opcional y está desactivado por defecto. Puede ver, exportar y eliminar "
            "todos los datos del servidor desde la pantalla « Transparencia de datos » dentro de la app."
        ),
        "h3_diagnostic": "2.5 Informes de error y diagnóstico (opt-in)",
        "p_diagnostic": (
            "Si activa los diagnósticos en Ajustes, se envían informes anónimos de fallos y trazas "
            "de rendimiento a Sentry. No se incluye ninguna información personal, ubicación ni "
            "contenido. Los diagnósticos están desactivados por defecto."
        ),
        "h2_not_collected": "3. Datos que NO recogemos",
        "li_nc_email": "Nombre, dirección de correo o número de teléfono",
        "li_nc_payment": "Información financiera o de pago",
        "li_nc_health": "Datos de salud o fitness",
        "li_nc_contacts": "Contactos, mensajes o registros de llamadas",
        "li_nc_photos": "Fotos, vídeos o archivos (el acceso a la cámara y a la galería se usa solo para escanear tickets cuando usted lo inicia)",
        "li_nc_history": "Historial de navegación",
        "li_nc_adid": "Identificadores publicitarios del dispositivo",
        "h2_third_parties": "4. Servicios de terceros",
        "p_third_parties_intro": "La app se comunica con las siguientes APIs de terceros:",
        "li_tk": "<strong>Tankerkönig</strong> (creativecommons.tankerkoenig.de) — precios alemanes. Recibe: coordenadas de búsqueda, su clave de API.",
        "li_pc": "<strong>Prix Carburants</strong> (data.economie.gouv.fr) — precios franceses. Recibe: coordenadas de búsqueda.",
        "li_it": "<strong>API italiana de precios</strong> (osservaprezzi.mise.gov.it) — precios italianos. Recibe: coordenadas de búsqueda.",
        "li_es": "<strong>API española de precios</strong> (sedeaplicaciones.minetur.gob.es) — precios españoles. Recibe: coordenadas de búsqueda.",
        "li_at": "<strong>Spritpreisrechner</strong> (spritpreisrechner.at) — precios austríacos. Recibe: coordenadas de búsqueda.",
        "li_be": "<strong>FuelWatch</strong> (fuelwatch.be) — precios belgas. Recibe: coordenadas de búsqueda.",
        "li_lu": "<strong>data.public.lu</strong> — precios luxemburgueses. Recibe: coordenadas de búsqueda.",
        "li_ocm": "<strong>OpenChargeMap</strong> (api.openchargemap.io) — puntos de recarga eléctrica. Recibe: coordenadas de búsqueda.",
        "li_nominatim": "<strong>Nominatim / OpenStreetMap</strong> (nominatim.openstreetmap.org) — geocodificación. Recibe: texto o coordenadas de búsqueda.",
        "li_osm": "<strong>Servidores de tiles OpenStreetMap</strong> (tile.openstreetmap.org) — tiles del mapa. Recibe: coordenadas del tile.",
        "li_supabase": "<strong>Supabase</strong> (solo si TankSync está activado) — backend de sincronización en la nube.",
        "li_sentry": "<strong>Sentry</strong> (solo si los diagnósticos están activados) — informes anónimos de fallos y rendimiento.",
        "p_third_parties_outro": (
            "Cada proveedor tiene su propia política de privacidad. Le recomendamos revisarlas. La "
            "app no comparte datos entre estos proveedores."
        ),
        "h2_security": "5. Seguridad de los datos",
        "li_sec_https": "Toda la comunicación de red usa HTTPS (cifrado TLS en tránsito).",
        "li_sec_keystore": "Las claves de API se almacenan en el almacenamiento cifrado nativo de la plataforma (Android Keystore / iOS Keychain).",
        "li_sec_local": "Los datos locales se almacenan en su dispositivo mediante Hive.",
        "li_sec_silent": "No se envían datos a ningún servidor a menos que inicie una búsqueda o active TankSync / los diagnósticos.",
        "h2_rights": "6. Sus derechos",
        "p_rights_intro": "Tiene derecho a:",
        "li_r_access": "<strong>Acceso</strong> — ver todos los datos almacenados localmente en la sección Almacenamiento de la app.",
        "li_r_export": "<strong>Exportación</strong> — exportar sus datos de TankSync como JSON desde la pantalla Transparencia de datos.",
        "li_r_delete": "<strong>Supresión</strong> — eliminar todos los datos locales mediante Ajustes → Eliminar todos los datos; eliminar todos los datos del servidor mediante TankSync → Transparencia de datos → Eliminar todo.",
        "li_r_withdraw": "<strong>Retirar el consentimiento</strong> — revocar el permiso de ubicación en los ajustes del sistema o desactivar TankSync / los diagnósticos en cualquier momento.",
        "h2_children": "7. Privacidad de los menores",
        "p_children": (
            "La aplicación no está dirigida a menores de 13 años. No recopilamos a sabiendas "
            "información personal de menores."
        ),
        "h2_changes": "8. Cambios en esta política",
        "p_changes": (
            "Podemos actualizar esta política de vez en cuando. Los cambios se publicarán en esta "
            "URL con una fecha actualizada. El uso continuado de la aplicación constituye aceptación "
            "de la política actualizada."
        ),
        "h2_contact": "9. Contacto",
        "contact_dev_label": "Desarrollador",
        "contact_email_label": "Correo",
        "contact_source_label": "Código fuente",
        "lang_switcher_label": "Idiomas disponibles:",
    },
    # Italian
    "it": {
        "html_lang": "it",
        "page_title": "Sparkilo — Informativa sulla privacy",
        "h1": "Informativa sulla privacy",
        "meta_app": "Sparkilo (de.tankstellen.tankstellen su iOS, de.tankstellen.fuelprices su Android)",
        "meta_last_updated": "Ultimo aggiornamento: 9 maggio 2026",
        "h2_overview": "1. Panoramica",
        "p_overview": (
            "Sparkilo (precedentemente Fuel Prices Europe & More) è un'app gratuita e open source "
            "per il confronto dei prezzi del carburante e delle stazioni di ricarica. È costruita "
            "secondo un'architettura <strong>local-first e rispettosa della privacy</strong>. "
            "Niente pubblicità, niente pixel di tracciamento, niente identificatori pubblicitari."
        ),
        "h2_collected": "2. Dati utilizzati",
        "h3_location": "2.1 Posizione approssimativa",
        "p_location": (
            "Quando concedi l'autorizzazione alla posizione, l'app legge la tua posizione "
            "approssimativa per trovare distributori e punti di ricarica nelle vicinanze. Le "
            "coordinate vengono inviate ad API di terze parti (vedi sezione 4) come parte della "
            "ricerca. La tua posizione <strong>non viene memorizzata su alcun server da noi gestito</strong> "
            "e non viene mai usata per tracciamento o profilazione."
        ),
        "h3_apikey": "2.2 Chiavi API che fornisci tu",
        "p_apikey": (
            "Se fornisci una tua chiave API (es. Tankerkönig), viene memorizzata localmente in "
            "uno storage cifrato (Android Keystore / iOS Keychain). La chiave viene inviata solo al "
            "fornitore di API corrispondente, mai a noi o a terzi."
        ),
        "h3_local": "2.3 Preferiti, profili e impostazioni",
        "p_local": (
            "Preferiti, profili di ricerca, preferenze di carburante e impostazioni dell'app sono "
            "memorizzati localmente sul tuo dispositivo tramite Hive, un database locale incorporato."
        ),
        "h3_sync": "2.4 TankSync (sincronizzazione cloud opzionale)",
        "p_sync_intro": "Se attivi TankSync, viene creato un account anonimo tramite Supabase. I dati sincronizzati sono:",
        "li_sync_id": "Identificatore utente anonimo (UUID — nessuna email, nessun nome)",
        "li_sync_fav": "ID dei distributori preferiti",
        "li_sync_alerts": "Configurazioni degli avvisi di prezzo",
        "li_sync_reports": "Segnalazioni di prezzo dalla community (ID distributore, tipo carburante, prezzo, timestamp)",
        "p_sync_outro": (
            "TankSync è opzionale e disattivato per impostazione predefinita. Puoi visualizzare, "
            "esportare ed eliminare tutti i dati lato server dalla schermata « Trasparenza dei dati » "
            "all'interno dell'app."
        ),
        "h3_diagnostic": "2.5 Rapporti di crash e diagnostica (opt-in)",
        "p_diagnostic": (
            "Se attivi la diagnostica nelle Impostazioni, vengono inviati a Sentry rapporti anonimi "
            "di crash e tracce di performance. Non viene incluso alcun dato personale, posizione "
            "o contenuto. La diagnostica è disattivata per impostazione predefinita."
        ),
        "h2_not_collected": "3. Dati che NON raccogliamo",
        "li_nc_email": "Nome, indirizzo email o numero di telefono",
        "li_nc_payment": "Informazioni finanziarie o di pagamento",
        "li_nc_health": "Dati di salute o fitness",
        "li_nc_contacts": "Contatti, messaggi o registri delle chiamate",
        "li_nc_photos": "Foto, video o file (l'accesso a fotocamera e libreria foto è usato solo per scansionare scontrini quando lo avvii tu)",
        "li_nc_history": "Cronologia di navigazione",
        "li_nc_adid": "Identificatori pubblicitari del dispositivo",
        "h2_third_parties": "4. Servizi di terze parti",
        "p_third_parties_intro": "L'app comunica con le seguenti API di terze parti:",
        "li_tk": "<strong>Tankerkönig</strong> (creativecommons.tankerkoenig.de) — prezzi tedeschi. Riceve: coordinate di ricerca, la tua chiave API.",
        "li_pc": "<strong>Prix Carburants</strong> (data.economie.gouv.fr) — prezzi francesi. Riceve: coordinate di ricerca.",
        "li_it": "<strong>API italiana dei prezzi</strong> (osservaprezzi.mise.gov.it) — prezzi italiani. Riceve: coordinate di ricerca.",
        "li_es": "<strong>API spagnola dei prezzi</strong> (sedeaplicaciones.minetur.gob.es) — prezzi spagnoli. Riceve: coordinate di ricerca.",
        "li_at": "<strong>Spritpreisrechner</strong> (spritpreisrechner.at) — prezzi austriaci. Riceve: coordinate di ricerca.",
        "li_be": "<strong>FuelWatch</strong> (fuelwatch.be) — prezzi belgi. Riceve: coordinate di ricerca.",
        "li_lu": "<strong>data.public.lu</strong> — prezzi lussemburghesi. Riceve: coordinate di ricerca.",
        "li_ocm": "<strong>OpenChargeMap</strong> (api.openchargemap.io) — stazioni di ricarica EV. Riceve: coordinate di ricerca.",
        "li_nominatim": "<strong>Nominatim / OpenStreetMap</strong> (nominatim.openstreetmap.org) — geocodifica. Riceve: testo o coordinate di ricerca.",
        "li_osm": "<strong>Server di tile OpenStreetMap</strong> (tile.openstreetmap.org) — tile della mappa. Riceve: coordinate del tile.",
        "li_supabase": "<strong>Supabase</strong> (solo se TankSync è attivo) — backend di sincronizzazione cloud.",
        "li_sentry": "<strong>Sentry</strong> (solo se la diagnostica è attiva) — rapporti anonimi di crash e performance.",
        "p_third_parties_outro": (
            "Ogni fornitore ha la propria informativa sulla privacy. Ti invitiamo a leggerle. L'app "
            "non condivide dati tra questi fornitori."
        ),
        "h2_security": "5. Sicurezza dei dati",
        "li_sec_https": "Tutte le comunicazioni di rete usano HTTPS (cifratura TLS in transito).",
        "li_sec_keystore": "Le chiavi API sono memorizzate nello storage cifrato nativo della piattaforma (Android Keystore / iOS Keychain).",
        "li_sec_local": "I dati locali vengono memorizzati sul tuo dispositivo tramite Hive.",
        "li_sec_silent": "Nessun dato viene inviato a server a meno che tu non avvii una ricerca o attivi TankSync / la diagnostica.",
        "h2_rights": "6. I tuoi diritti",
        "p_rights_intro": "Hai il diritto di:",
        "li_r_access": "<strong>Accesso</strong> — visualizzare tutti i dati memorizzati localmente nella sezione Archiviazione dell'app.",
        "li_r_export": "<strong>Esportazione</strong> — esportare i tuoi dati TankSync in JSON dalla schermata Trasparenza dei dati.",
        "li_r_delete": "<strong>Cancellazione</strong> — eliminare tutti i dati locali tramite Impostazioni → Elimina tutti i dati; eliminare tutti i dati del server tramite TankSync → Trasparenza dei dati → Elimina tutto.",
        "li_r_withdraw": "<strong>Revocare il consenso</strong> — revocare l'autorizzazione alla posizione nelle impostazioni del dispositivo o disattivare TankSync / la diagnostica in qualsiasi momento.",
        "h2_children": "7. Privacy dei minori",
        "p_children": (
            "L'app non è destinata a bambini sotto i 13 anni. Non raccogliamo consapevolmente "
            "informazioni personali dai minori."
        ),
        "h2_changes": "8. Modifiche a questa informativa",
        "p_changes": (
            "Potremmo aggiornare periodicamente questa informativa. Le modifiche saranno pubblicate "
            "a questo URL con una data aggiornata. L'uso continuato dell'app costituisce accettazione "
            "della versione aggiornata."
        ),
        "h2_contact": "9. Contatti",
        "contact_dev_label": "Sviluppatore",
        "contact_email_label": "Email",
        "contact_source_label": "Codice sorgente",
        "lang_switcher_label": "Lingue disponibili:",
    },
    # Dutch
    "nl": {
        "html_lang": "nl",
        "page_title": "Sparkilo — Privacybeleid",
        "h1": "Privacybeleid",
        "meta_app": "Sparkilo (de.tankstellen.tankstellen op iOS, de.tankstellen.fuelprices op Android)",
        "meta_last_updated": "Laatst bijgewerkt: 9 mei 2026",
        "h2_overview": "1. Overzicht",
        "p_overview": (
            "Sparkilo (voorheen Fuel Prices Europe & More) is een gratis open-source app om "
            "brandstof- en laadprijzen te vergelijken. De app is gebouwd op een "
            "<strong>local-first, privacyvriendelijke</strong> architectuur. Geen advertenties, "
            "geen tracking pixels, geen advertentie-ID's."
        ),
        "h2_collected": "2. Welke gegevens we gebruiken",
        "h3_location": "2.1 Bij benadering locatie",
        "p_location": (
            "Wanneer u de locatietoestemming verleent, leest de app uw geschatte positie om "
            "tankstations en laadpunten in de buurt te vinden. De coördinaten worden naar "
            "API's van derden gestuurd (zie sectie 4) als onderdeel van de zoekopdracht. Uw "
            "locatie <strong>wordt niet opgeslagen op een server die wij beheren</strong> en wordt "
            "nooit gebruikt voor tracking of profilering."
        ),
        "h3_apikey": "2.2 API-sleutels die u zelf opgeeft",
        "p_apikey": (
            "Als u een eigen API-sleutel opgeeft (bijv. Tankerkönig), wordt deze lokaal opgeslagen "
            "in versleutelde opslag (Android Keystore / iOS Keychain). De sleutel wordt alleen naar "
            "de bijbehorende API-aanbieder verzonden, nooit naar ons of derden."
        ),
        "h3_local": "2.3 Favorieten, profielen en instellingen",
        "p_local": (
            "Uw favorieten, zoekprofielen, brandstofvoorkeuren en app-instellingen worden lokaal op "
            "uw toestel opgeslagen via Hive, een ingebedde lokale database."
        ),
        "h3_sync": "2.4 TankSync (optionele cloud-sync)",
        "p_sync_intro": "Als u TankSync inschakelt, wordt een anoniem account aangemaakt via Supabase. Gesynchroniseerde gegevens:",
        "li_sync_id": "Anonieme gebruikers-ID (UUID — geen e-mail, geen naam)",
        "li_sync_fav": "ID's van favoriete tankstations",
        "li_sync_alerts": "Configuraties van prijswaarschuwingen",
        "li_sync_reports": "Community-prijsmeldingen (station-ID, brandstofsoort, prijs, tijdstempel)",
        "p_sync_outro": (
            "TankSync is optioneel en standaard uitgeschakeld. U kunt alle servergegevens bekijken, "
            "exporteren en verwijderen via het scherm « Datatransparantie » in de app."
        ),
        "h3_diagnostic": "2.5 Crash- en diagnoserapporten (opt-in)",
        "p_diagnostic": (
            "Als u diagnose inschakelt in Instellingen, worden anonieme crashrapporten en "
            "performance-traces naar Sentry verzonden. Er worden geen persoonlijke gegevens, "
            "locatie of inhoud meegestuurd. Diagnose staat standaard uit."
        ),
        "h2_not_collected": "3. Gegevens die we NIET verzamelen",
        "li_nc_email": "Naam, e-mailadres of telefoonnummer",
        "li_nc_payment": "Financiële of betalingsgegevens",
        "li_nc_health": "Gezondheids- of fitnessgegevens",
        "li_nc_contacts": "Contacten, berichten of belregistraties",
        "li_nc_photos": "Foto's, video's of bestanden (toegang tot camera en fotomappen wordt alleen gebruikt om bonnetjes te scannen wanneer u dat zelf start)",
        "li_nc_history": "Browse-geschiedenis",
        "li_nc_adid": "Reclame-ID's van het toestel",
        "h2_third_parties": "4. Diensten van derden",
        "p_third_parties_intro": "De app communiceert met de volgende API's van derden:",
        "li_tk": "<strong>Tankerkönig</strong> (creativecommons.tankerkoenig.de) — Duitse prijzen. Ontvangt: zoekcoördinaten, uw API-sleutel.",
        "li_pc": "<strong>Prix Carburants</strong> (data.economie.gouv.fr) — Franse prijzen. Ontvangt: zoekcoördinaten.",
        "li_it": "<strong>Italiaanse prijs-API</strong> (osservaprezzi.mise.gov.it) — Italiaanse prijzen. Ontvangt: zoekcoördinaten.",
        "li_es": "<strong>Spaanse prijs-API</strong> (sedeaplicaciones.minetur.gob.es) — Spaanse prijzen. Ontvangt: zoekcoördinaten.",
        "li_at": "<strong>Spritpreisrechner</strong> (spritpreisrechner.at) — Oostenrijkse prijzen. Ontvangt: zoekcoördinaten.",
        "li_be": "<strong>FuelWatch</strong> (fuelwatch.be) — Belgische prijzen. Ontvangt: zoekcoördinaten.",
        "li_lu": "<strong>data.public.lu</strong> — Luxemburgse prijzen. Ontvangt: zoekcoördinaten.",
        "li_ocm": "<strong>OpenChargeMap</strong> (api.openchargemap.io) — laadpunten voor EV's. Ontvangt: zoekcoördinaten.",
        "li_nominatim": "<strong>Nominatim / OpenStreetMap</strong> (nominatim.openstreetmap.org) — geocodering. Ontvangt: zoektekst of coördinaten.",
        "li_osm": "<strong>OpenStreetMap-tile-servers</strong> (tile.openstreetmap.org) — kaarttegels. Ontvangt: tegelcoördinaten.",
        "li_supabase": "<strong>Supabase</strong> (alleen als TankSync is ingeschakeld) — cloud-sync-backend.",
        "li_sentry": "<strong>Sentry</strong> (alleen als diagnose is ingeschakeld) — anonieme crash- en performance-rapporten.",
        "p_third_parties_outro": (
            "Elke aanbieder heeft een eigen privacybeleid. We raden u aan deze te lezen. De app "
            "deelt geen gegevens tussen deze aanbieders."
        ),
        "h2_security": "5. Gegevensbeveiliging",
        "li_sec_https": "Alle netwerkcommunicatie verloopt via HTTPS (TLS-versleuteling tijdens transport).",
        "li_sec_keystore": "API-sleutels worden opgeslagen in de native versleutelde opslag van het platform (Android Keystore / iOS Keychain).",
        "li_sec_local": "Lokale gegevens worden op uw toestel opgeslagen via Hive.",
        "li_sec_silent": "Er worden geen gegevens naar een server verzonden tenzij u een zoekopdracht start of TankSync / diagnose inschakelt.",
        "h2_rights": "6. Uw rechten",
        "p_rights_intro": "U heeft het recht om:",
        "li_r_access": "<strong>Inzage</strong> — alle lokaal opgeslagen gegevens te bekijken in de Opslag-sectie van de app.",
        "li_r_export": "<strong>Export</strong> — uw TankSync-gegevens als JSON te exporteren via het scherm Datatransparantie.",
        "li_r_delete": "<strong>Verwijdering</strong> — alle lokale gegevens te verwijderen via Instellingen → Alle gegevens verwijderen; alle servergegevens via TankSync → Datatransparantie → Alles verwijderen.",
        "li_r_withdraw": "<strong>Toestemming intrekken</strong> — locatietoestemming intrekken in de toestelinstellingen of TankSync / diagnose op elk moment uitschakelen.",
        "h2_children": "7. Privacy van kinderen",
        "p_children": (
            "De app is niet gericht op kinderen jonger dan 13. We verzamelen niet bewust "
            "persoonlijke gegevens van kinderen."
        ),
        "h2_changes": "8. Wijzigingen in dit beleid",
        "p_changes": (
            "We kunnen dit beleid van tijd tot tijd aanpassen. Wijzigingen worden op deze URL "
            "gepubliceerd met een bijgewerkte datum. Voortgezet gebruik van de app betekent "
            "aanvaarding van het bijgewerkte beleid."
        ),
        "h2_contact": "9. Contact",
        "contact_dev_label": "Ontwikkelaar",
        "contact_email_label": "E-mail",
        "contact_source_label": "Broncode",
        "lang_switcher_label": "Beschikbare talen:",
    },
    # Portuguese (works for both pt-PT and pt-BR)
    "pt": {
        "html_lang": "pt",
        "page_title": "Sparkilo — Política de privacidade",
        "h1": "Política de privacidade",
        "meta_app": "Sparkilo (de.tankstellen.tankstellen no iOS, de.tankstellen.fuelprices no Android)",
        "meta_last_updated": "Última atualização: 9 de maio de 2026",
        "h2_overview": "1. Visão geral",
        "p_overview": (
            "O Sparkilo (anteriormente Fuel Prices Europe & More) é uma aplicação gratuita e de "
            "código aberto para comparar preços de combustível e de pontos de carregamento "
            "elétrico. É construída segundo uma arquitetura <strong>local-first, respeitadora da "
            "privacidade</strong>. Sem anúncios, sem píxeis de rastreamento, sem identificadores "
            "publicitários."
        ),
        "h2_collected": "2. Dados que utilizamos",
        "h3_location": "2.1 Localização aproximada",
        "p_location": (
            "Quando concede a permissão de localização, a app lê a sua posição aproximada para "
            "encontrar postos e pontos de carregamento próximos. As coordenadas são enviadas a "
            "APIs de terceiros (ver secção 4) como parte da consulta. A sua localização "
            "<strong>não é armazenada em nenhum servidor que operamos</strong> e nunca é usada "
            "para rastreamento ou perfis."
        ),
        "h3_apikey": "2.2 Chaves de API que você fornece",
        "p_apikey": (
            "Se fornecer a sua própria chave de API (por exemplo, Tankerkönig), ela é guardada "
            "localmente em armazenamento cifrado (Android Keystore / iOS Keychain). A chave é "
            "enviada apenas ao fornecedor de API correspondente, nunca a nós nem a terceiros."
        ),
        "h3_local": "2.3 Favoritos, perfis e definições",
        "p_local": (
            "Os seus favoritos, perfis de pesquisa, preferências de combustível e definições da "
            "app são guardados localmente no seu dispositivo através do Hive, uma base de dados "
            "local incorporada."
        ),
        "h3_sync": "2.4 TankSync (sincronização na nuvem opcional)",
        "p_sync_intro": "Se ativar o TankSync, é criada uma conta anónima através do Supabase. Os dados sincronizados são:",
        "li_sync_id": "Identificador anónimo de utilizador (UUID — sem email nem nome)",
        "li_sync_fav": "IDs dos postos favoritos",
        "li_sync_alerts": "Configurações de alertas de preço",
        "li_sync_reports": "Relatos comunitários de preço (ID do posto, tipo de combustível, preço, carimbo de tempo)",
        "p_sync_outro": (
            "O TankSync é opcional e desativado por predefinição. Pode ver, exportar e eliminar "
            "todos os dados do servidor a partir do ecrã « Transparência de dados » dentro da app."
        ),
        "h3_diagnostic": "2.5 Relatórios de erro e diagnóstico (opt-in)",
        "p_diagnostic": (
            "Se ativar os diagnósticos nas Definições, são enviados ao Sentry relatórios anónimos "
            "de erro e traços de desempenho. Não é incluída nenhuma informação pessoal, "
            "localização nem conteúdo. Os diagnósticos estão desativados por predefinição."
        ),
        "h2_not_collected": "3. Dados que NÃO recolhemos",
        "li_nc_email": "Nome, endereço de email ou número de telefone",
        "li_nc_payment": "Informações financeiras ou de pagamento",
        "li_nc_health": "Dados de saúde ou de fitness",
        "li_nc_contacts": "Contactos, mensagens ou registos de chamadas",
        "li_nc_photos": "Fotos, vídeos ou ficheiros (o acesso à câmara e à galeria é usado apenas para digitalizar talões quando você inicia)",
        "li_nc_history": "Histórico de navegação",
        "li_nc_adid": "Identificadores publicitários do dispositivo",
        "h2_third_parties": "4. Serviços de terceiros",
        "p_third_parties_intro": "A app comunica com as seguintes APIs de terceiros:",
        "li_tk": "<strong>Tankerkönig</strong> (creativecommons.tankerkoenig.de) — preços alemães. Recebe: coordenadas de pesquisa, a sua chave de API.",
        "li_pc": "<strong>Prix Carburants</strong> (data.economie.gouv.fr) — preços franceses. Recebe: coordenadas de pesquisa.",
        "li_it": "<strong>API italiana de preços</strong> (osservaprezzi.mise.gov.it) — preços italianos. Recebe: coordenadas de pesquisa.",
        "li_es": "<strong>API espanhola de preços</strong> (sedeaplicaciones.minetur.gob.es) — preços espanhóis. Recebe: coordenadas de pesquisa.",
        "li_at": "<strong>Spritpreisrechner</strong> (spritpreisrechner.at) — preços austríacos. Recebe: coordenadas de pesquisa.",
        "li_be": "<strong>FuelWatch</strong> (fuelwatch.be) — preços belgas. Recebe: coordenadas de pesquisa.",
        "li_lu": "<strong>data.public.lu</strong> — preços luxemburgueses. Recebe: coordenadas de pesquisa.",
        "li_ocm": "<strong>OpenChargeMap</strong> (api.openchargemap.io) — pontos de carregamento. Recebe: coordenadas de pesquisa.",
        "li_nominatim": "<strong>Nominatim / OpenStreetMap</strong> (nominatim.openstreetmap.org) — geocodificação. Recebe: texto ou coordenadas de pesquisa.",
        "li_osm": "<strong>Servidores de tiles do OpenStreetMap</strong> (tile.openstreetmap.org) — tiles do mapa. Recebe: coordenadas do tile.",
        "li_supabase": "<strong>Supabase</strong> (apenas se o TankSync estiver ativado) — backend de sincronização na nuvem.",
        "li_sentry": "<strong>Sentry</strong> (apenas se os diagnósticos estiverem ativados) — relatórios anónimos de erro e desempenho.",
        "p_third_parties_outro": (
            "Cada fornecedor tem a sua própria política de privacidade. Recomendamos que as "
            "consulte. A app não partilha dados entre estes fornecedores."
        ),
        "h2_security": "5. Segurança dos dados",
        "li_sec_https": "Toda a comunicação em rede usa HTTPS (cifragem TLS em trânsito).",
        "li_sec_keystore": "As chaves de API são guardadas no armazenamento cifrado nativo da plataforma (Android Keystore / iOS Keychain).",
        "li_sec_local": "Os dados locais são guardados no seu dispositivo através do Hive.",
        "li_sec_silent": "Não são enviados dados para qualquer servidor a menos que inicie uma pesquisa ou ative o TankSync / diagnósticos.",
        "h2_rights": "6. Os seus direitos",
        "p_rights_intro": "Tem o direito de:",
        "li_r_access": "<strong>Acesso</strong> — ver todos os dados guardados localmente na secção Armazenamento da app.",
        "li_r_export": "<strong>Exportação</strong> — exportar os seus dados TankSync em JSON a partir do ecrã Transparência de dados.",
        "li_r_delete": "<strong>Eliminação</strong> — eliminar todos os dados locais via Definições → Eliminar todos os dados; eliminar todos os dados de servidor via TankSync → Transparência de dados → Eliminar tudo.",
        "li_r_withdraw": "<strong>Retirar consentimento</strong> — revogar a permissão de localização nas definições do dispositivo, ou desativar o TankSync / diagnósticos a qualquer momento.",
        "h2_children": "7. Privacidade de crianças",
        "p_children": (
            "A app não é dirigida a crianças com menos de 13 anos. Não recolhemos conscientemente "
            "informação pessoal de crianças."
        ),
        "h2_changes": "8. Alterações a esta política",
        "p_changes": (
            "Podemos atualizar esta política periodicamente. As alterações serão publicadas neste "
            "URL com uma data atualizada. A continuação do uso da app constitui aceitação da "
            "política atualizada."
        ),
        "h2_contact": "9. Contacto",
        "contact_dev_label": "Programador",
        "contact_email_label": "Email",
        "contact_source_label": "Código-fonte",
        "lang_switcher_label": "Idiomas disponíveis:",
    },
    # Swedish
    "sv": {
        "html_lang": "sv",
        "page_title": "Sparkilo — Integritetspolicy",
        "h1": "Integritetspolicy",
        "meta_app": "Sparkilo (de.tankstellen.tankstellen på iOS, de.tankstellen.fuelprices på Android)",
        "meta_last_updated": "Senast uppdaterad: 9 maj 2026",
        "h2_overview": "1. Översikt",
        "p_overview": (
            "Sparkilo (tidigare Fuel Prices Europe & More) är en gratis öppen källkods-app för "
            "jämförelse av drivmedels- och laddpriser. Den är byggd kring en "
            "<strong>local-first, integritetsvänlig</strong> arkitektur. Inga annonser, inga "
            "spårningspixlar, inga annons-ID:n."
        ),
        "h2_collected": "2. Data vi använder",
        "h3_location": "2.1 Ungefärlig plats",
        "p_location": (
            "När du beviljar platsbehörighet läser appen din ungefärliga position för att hitta "
            "drivmedels- och laddstationer i närheten. Koordinaterna skickas till tredje parts "
            "API:er (se avsnitt 4) som en del av sökningen. Din position "
            "<strong>lagras inte på någon server vi driver</strong> och används aldrig för "
            "spårning eller profilering."
        ),
        "h3_apikey": "2.2 API-nycklar du anger själv",
        "p_apikey": (
            "Om du anger en egen API-nyckel (t.ex. Tankerkönig) lagras den lokalt i krypterad "
            "lagring (Android Keystore / iOS Keychain). Nyckeln skickas endast till motsvarande "
            "API-leverantör, aldrig till oss eller till tredje part."
        ),
        "h3_local": "2.3 Favoriter, profiler och inställningar",
        "p_local": (
            "Dina favoriter, sökprofiler, drivmedelsval och appinställningar lagras lokalt på "
            "din enhet via Hive, en inbyggd lokal databas."
        ),
        "h3_sync": "2.4 TankSync (valfri molnsynkronisering)",
        "p_sync_intro": "Om du aktiverar TankSync skapas ett anonymt konto via Supabase. Synkroniserade data:",
        "li_sync_id": "Anonym användar-ID (UUID — ingen e-post eller namn)",
        "li_sync_fav": "ID:n för favoritstationer",
        "li_sync_alerts": "Konfigurationer för prislarm",
        "li_sync_reports": "Communityrapporter om priser (stations-ID, drivmedelstyp, pris, tidsstämpel)",
        "p_sync_outro": (
            "TankSync är valfritt och inaktiverat som standard. Du kan visa, exportera och radera "
            "all serverdata från skärmen « Datatransparens » i appen."
        ),
        "h3_diagnostic": "2.5 Krasch- och diagnosrapporter (opt-in)",
        "p_diagnostic": (
            "Om du aktiverar diagnos i Inställningar skickas anonyma kraschrapporter och "
            "prestandaspår till Sentry. Ingen personlig information, plats eller innehåll "
            "ingår. Diagnos är avstängd som standard."
        ),
        "h2_not_collected": "3. Data vi INTE samlar in",
        "li_nc_email": "Namn, e-postadress eller telefonnummer",
        "li_nc_payment": "Finansiell information eller betalningsuppgifter",
        "li_nc_health": "Hälso- eller träningsdata",
        "li_nc_contacts": "Kontakter, meddelanden eller samtalsloggar",
        "li_nc_photos": "Foton, videor eller filer (åtkomst till kamera och bildbibliotek används endast för kvittoskanning som du själv startar)",
        "li_nc_history": "Webbhistorik",
        "li_nc_adid": "Annons-ID:n från enheten",
        "h2_third_parties": "4. Tredjepartstjänster",
        "p_third_parties_intro": "Appen kommunicerar med följande tredjeparts-API:er:",
        "li_tk": "<strong>Tankerkönig</strong> (creativecommons.tankerkoenig.de) — tyska priser. Tar emot: sökkoordinater, din API-nyckel.",
        "li_pc": "<strong>Prix Carburants</strong> (data.economie.gouv.fr) — franska priser. Tar emot: sökkoordinater.",
        "li_it": "<strong>Italiensk pris-API</strong> (osservaprezzi.mise.gov.it) — italienska priser. Tar emot: sökkoordinater.",
        "li_es": "<strong>Spansk pris-API</strong> (sedeaplicaciones.minetur.gob.es) — spanska priser. Tar emot: sökkoordinater.",
        "li_at": "<strong>Spritpreisrechner</strong> (spritpreisrechner.at) — österrikiska priser. Tar emot: sökkoordinater.",
        "li_be": "<strong>FuelWatch</strong> (fuelwatch.be) — belgiska priser. Tar emot: sökkoordinater.",
        "li_lu": "<strong>data.public.lu</strong> — luxemburgska priser. Tar emot: sökkoordinater.",
        "li_ocm": "<strong>OpenChargeMap</strong> (api.openchargemap.io) — laddstationer. Tar emot: sökkoordinater.",
        "li_nominatim": "<strong>Nominatim / OpenStreetMap</strong> (nominatim.openstreetmap.org) — geokodning. Tar emot: söktext eller koordinater.",
        "li_osm": "<strong>OpenStreetMap-tile-servrar</strong> (tile.openstreetmap.org) — kartrutor. Tar emot: rutkoordinater.",
        "li_supabase": "<strong>Supabase</strong> (endast om TankSync är aktivt) — backend för molnsynkronisering.",
        "li_sentry": "<strong>Sentry</strong> (endast om diagnos är aktiv) — anonyma krasch- och prestandarapporter.",
        "p_third_parties_outro": (
            "Varje leverantör har en egen integritetspolicy. Vi rekommenderar att du läser dem. "
            "Appen delar inte data mellan dessa leverantörer."
        ),
        "h2_security": "5. Datasäkerhet",
        "li_sec_https": "All nätverkskommunikation använder HTTPS (TLS-kryptering under transport).",
        "li_sec_keystore": "API-nycklar lagras i plattformens nativa krypterade lagring (Android Keystore / iOS Keychain).",
        "li_sec_local": "Lokal data lagras på din enhet via Hive.",
        "li_sec_silent": "Inga data skickas till någon server om du inte själv startar en sökning eller aktiverar TankSync / diagnos.",
        "h2_rights": "6. Dina rättigheter",
        "p_rights_intro": "Du har rätt att:",
        "li_r_access": "<strong>Få åtkomst</strong> — visa all lokalt lagrad data i appens Lagring-avsnitt.",
        "li_r_export": "<strong>Exportera</strong> — exportera dina TankSync-data som JSON från skärmen Datatransparens.",
        "li_r_delete": "<strong>Radera</strong> — radera all lokal data via Inställningar → Radera all data; radera all serverdata via TankSync → Datatransparens → Radera allt.",
        "li_r_withdraw": "<strong>Återkalla samtycke</strong> — återkalla platsbehörigheten i enhetens inställningar, eller stänga av TankSync / diagnos när som helst.",
        "h2_children": "7. Barns integritet",
        "p_children": (
            "Appen riktar sig inte till barn under 13 år. Vi samlar inte medvetet in personlig "
            "information från barn."
        ),
        "h2_changes": "8. Ändringar i denna policy",
        "p_changes": (
            "Vi kan uppdatera denna policy från tid till annan. Ändringar publiceras på denna "
            "URL med ett uppdaterat datum. Fortsatt användning av appen utgör godkännande av "
            "den uppdaterade policyn."
        ),
        "h2_contact": "9. Kontakt",
        "contact_dev_label": "Utvecklare",
        "contact_email_label": "E-post",
        "contact_source_label": "Källkod",
        "lang_switcher_label": "Tillgängliga språk:",
    },
    # Finnish
    "fi": {
        "html_lang": "fi",
        "page_title": "Sparkilo — Tietosuojakäytäntö",
        "h1": "Tietosuojakäytäntö",
        "meta_app": "Sparkilo (de.tankstellen.tankstellen iOS:llä, de.tankstellen.fuelprices Androidilla)",
        "meta_last_updated": "Viimeksi päivitetty: 9. toukokuuta 2026",
        "h2_overview": "1. Yleiskatsaus",
        "p_overview": (
            "Sparkilo (aiemmin Fuel Prices Europe & More) on ilmainen avoimen lähdekoodin "
            "sovellus polttoaine- ja latausasemien hintojen vertailuun. Se on rakennettu "
            "<strong>local-first, yksityisyyttä kunnioittavalle</strong> arkkitehtuurille. "
            "Ei mainoksia, ei seurantapikseleitä, ei mainostunnisteita."
        ),
        "h2_collected": "2. Käyttämämme tiedot",
        "h3_location": "2.1 Likimääräinen sijainti",
        "p_location": (
            "Kun annat sijaintiluvan, sovellus lukee likimääräisen sijaintisi löytääkseen "
            "lähimmät polttoaine- ja latausasemat. Koordinaatit lähetetään kolmansien osapuolien "
            "rajapintoihin (ks. luku 4) hakuna. Sijaintiasi <strong>ei tallenneta millekään "
            "ylläpitämällemme palvelimelle</strong>, eikä sitä koskaan käytetä seurantaan tai "
            "profilointiin."
        ),
        "h3_apikey": "2.2 Itse antamasi API-avaimet",
        "p_apikey": (
            "Jos annat oman API-avaimesi (esim. Tankerkönig), se tallennetaan paikallisesti "
            "salattuun säilöön (Android Keystore / iOS Keychain). Avain lähetetään vain vastaavalle "
            "API-tarjoajalle, ei meille eikä kolmansille osapuolille."
        ),
        "h3_local": "2.3 Suosikit, profiilit ja asetukset",
        "p_local": (
            "Suosikkisi, hakuprofiilisi, polttoainemieltymyksesi ja sovellusasetuksesi tallennetaan "
            "paikallisesti laitteellesi Hive-tietokantaan."
        ),
        "h3_sync": "2.4 TankSync (valinnainen pilvisynkronointi)",
        "p_sync_intro": "Jos otat TankSyncin käyttöön, Supabaseen luodaan anonyymi tili. Synkronoitavat tiedot:",
        "li_sync_id": "Anonyymi käyttäjätunnus (UUID — ei sähköpostia, ei nimeä)",
        "li_sync_fav": "Suosikkiasemien tunnukset",
        "li_sync_alerts": "Hintahälytysten asetukset",
        "li_sync_reports": "Yhteisön hintailmoitukset (aseman tunnus, polttoainetyyppi, hinta, aikaleima)",
        "p_sync_outro": (
            "TankSync on valinnainen ja oletuksena pois käytöstä. Voit tarkastella, viedä ja "
            "poistaa kaikki palvelinpuolen tiedot sovelluksen « Tietojen läpinäkyvyys » -näytöltä."
        ),
        "h3_diagnostic": "2.5 Kaatumis- ja diagnostiikkaraportit (opt-in)",
        "p_diagnostic": (
            "Jos otat diagnostiikan käyttöön Asetuksissa, anonyymejä kaatumisraportteja ja "
            "suorituskykyjälkiä lähetetään Sentryyn. Mitään henkilötietoja, sijaintia tai "
            "sisältöä ei sisällytetä. Diagnostiikka on oletuksena pois käytöstä."
        ),
        "h2_not_collected": "3. Tiedot, joita EMME kerää",
        "li_nc_email": "Nimi, sähköpostiosoite tai puhelinnumero",
        "li_nc_payment": "Talous- tai maksutiedot",
        "li_nc_health": "Terveys- tai kuntotiedot",
        "li_nc_contacts": "Yhteystiedot, viestit tai puhelulokit",
        "li_nc_photos": "Valokuvat, videot tai tiedostot (kameran ja kuvakirjaston käyttö on vain kuittien skannaukseen, jonka aloitat itse)",
        "li_nc_history": "Selaushistoria",
        "li_nc_adid": "Laitteen mainostunnisteet",
        "h2_third_parties": "4. Kolmannen osapuolen palvelut",
        "p_third_parties_intro": "Sovellus on yhteydessä seuraaviin kolmannen osapuolen rajapintoihin:",
        "li_tk": "<strong>Tankerkönig</strong> (creativecommons.tankerkoenig.de) — Saksan hinnat. Vastaanottaa: hakukoordinaatit, API-avaimesi.",
        "li_pc": "<strong>Prix Carburants</strong> (data.economie.gouv.fr) — Ranskan hinnat. Vastaanottaa: hakukoordinaatit.",
        "li_it": "<strong>Italian hintarajapinta</strong> (osservaprezzi.mise.gov.it) — Italian hinnat. Vastaanottaa: hakukoordinaatit.",
        "li_es": "<strong>Espanjan hintarajapinta</strong> (sedeaplicaciones.minetur.gob.es) — Espanjan hinnat. Vastaanottaa: hakukoordinaatit.",
        "li_at": "<strong>Spritpreisrechner</strong> (spritpreisrechner.at) — Itävallan hinnat. Vastaanottaa: hakukoordinaatit.",
        "li_be": "<strong>FuelWatch</strong> (fuelwatch.be) — Belgian hinnat. Vastaanottaa: hakukoordinaatit.",
        "li_lu": "<strong>data.public.lu</strong> — Luxemburgin hinnat. Vastaanottaa: hakukoordinaatit.",
        "li_ocm": "<strong>OpenChargeMap</strong> (api.openchargemap.io) — latauspisteet. Vastaanottaa: hakukoordinaatit.",
        "li_nominatim": "<strong>Nominatim / OpenStreetMap</strong> (nominatim.openstreetmap.org) — geokoodaus. Vastaanottaa: hakuteksti tai koordinaatit.",
        "li_osm": "<strong>OpenStreetMap-tile-palvelimet</strong> (tile.openstreetmap.org) — karttalaatat. Vastaanottaa: laatan koordinaatit.",
        "li_supabase": "<strong>Supabase</strong> (vain jos TankSync on käytössä) — pilvisynkronoinnin taustajärjestelmä.",
        "li_sentry": "<strong>Sentry</strong> (vain jos diagnostiikka on käytössä) — anonyymit kaatumis- ja suorituskykyraportit.",
        "p_third_parties_outro": (
            "Jokaisella tarjoajalla on oma tietosuojakäytäntönsä. Suosittelemme tutustumaan niihin. "
            "Sovellus ei jaa tietoja näiden tarjoajien välillä."
        ),
        "h2_security": "5. Tietoturva",
        "li_sec_https": "Kaikki verkkoliikenne kulkee HTTPS:n kautta (TLS-salaus siirron aikana).",
        "li_sec_keystore": "API-avaimet tallennetaan alustan natiiviin salattuun säilöön (Android Keystore / iOS Keychain).",
        "li_sec_local": "Paikalliset tiedot tallennetaan laitteellesi Hiven kautta.",
        "li_sec_silent": "Mitään tietoja ei lähetetä millekään palvelimelle, ellet käynnistä hakua tai ota TankSynciä / diagnostiikkaa käyttöön.",
        "h2_rights": "6. Oikeutesi",
        "p_rights_intro": "Sinulla on oikeus:",
        "li_r_access": "<strong>Tutustua</strong> — kaikkiin paikallisesti tallennettuihin tietoihin sovelluksen Tallennustila-osiossa.",
        "li_r_export": "<strong>Viedä</strong> — TankSync-tietosi JSON-muodossa Tietojen läpinäkyvyys -näytöltä.",
        "li_r_delete": "<strong>Poistaa</strong> — kaikki paikalliset tiedot kohdasta Asetukset → Poista kaikki tiedot; kaikki palvelintiedot kohdasta TankSync → Tietojen läpinäkyvyys → Poista kaikki.",
        "li_r_withdraw": "<strong>Peruuttaa suostumuksesi</strong> — peruuta sijaintilupa laitteen asetuksista tai poista TankSync / diagnostiikka käytöstä milloin tahansa.",
        "h2_children": "7. Lasten yksityisyys",
        "p_children": (
            "Sovellusta ei ole suunnattu alle 13-vuotiaille lapsille. Emme tietoisesti kerää "
            "henkilötietoja lapsilta."
        ),
        "h2_changes": "8. Muutokset tähän käytäntöön",
        "p_changes": (
            "Voimme päivittää tätä käytäntöä ajoittain. Muutokset julkaistaan tässä osoitteessa "
            "päivitetyllä päivämäärällä. Sovelluksen käytön jatkaminen tarkoittaa päivitetyn "
            "käytännön hyväksymistä."
        ),
        "h2_contact": "9. Yhteystiedot",
        "contact_dev_label": "Kehittäjä",
        "contact_email_label": "Sähköposti",
        "contact_source_label": "Lähdekoodi",
        "lang_switcher_label": "Saatavilla olevat kielet:",
    },
    # Danish
    "da": {
        "html_lang": "da",
        "page_title": "Sparkilo — Privatlivspolitik",
        "h1": "Privatlivspolitik",
        "meta_app": "Sparkilo (de.tankstellen.tankstellen på iOS, de.tankstellen.fuelprices på Android)",
        "meta_last_updated": "Senest opdateret: 9. maj 2026",
        "h2_overview": "1. Oversigt",
        "p_overview": (
            "Sparkilo (tidligere Fuel Prices Europe & More) er en gratis open source-app til "
            "sammenligning af brændstofpriser og ladestander­priser. Den er bygget på en "
            "<strong>local-first, privatlivsvenlig</strong> arkitektur. Ingen reklamer, ingen "
            "sporings­pixels, ingen reklame-id'er."
        ),
        "h2_collected": "2. Data vi bruger",
        "h3_location": "2.1 Omtrentlig placering",
        "p_location": (
            "Når du giver placerings­tilladelse, læser appen din omtrentlige position for at "
            "finde brændstof- og ladestationer i nærheden. Koordinaterne sendes til "
            "tredjeparts-API'er (se afsnit 4) som en del af forespørgslen. Din placering "
            "<strong>opbevares ikke på nogen server, vi driver</strong>, og bruges aldrig til "
            "sporing eller profilering."
        ),
        "h3_apikey": "2.2 API-nøgler du selv angiver",
        "p_apikey": (
            "Hvis du angiver din egen API-nøgle (fx Tankerkönig), gemmes den lokalt i krypteret "
            "lager (Android Keystore / iOS Keychain). Nøglen sendes kun til den tilsvarende "
            "API-udbyder, aldrig til os eller tredjeparter."
        ),
        "h3_local": "2.3 Favoritter, profiler og indstillinger",
        "p_local": (
            "Dine favoritter, søgeprofiler, brændstofpræferencer og app-indstillinger gemmes "
            "lokalt på din enhed via Hive, en indlejret lokal database."
        ),
        "h3_sync": "2.4 TankSync (valgfri cloud-synk)",
        "p_sync_intro": "Hvis du aktiverer TankSync, oprettes en anonym konto via Supabase. Synkroniserede data:",
        "li_sync_id": "Anonymt bruger-id (UUID — ingen e-mail, intet navn)",
        "li_sync_fav": "Id'er for favorit­stationer",
        "li_sync_alerts": "Konfiguration af prisalarmer",
        "li_sync_reports": "Community-prisrapporter (stations-id, brændstoftype, pris, tidsstempel)",
        "p_sync_outro": (
            "TankSync er valgfri og som standard slået fra. Du kan se, eksportere og slette alle "
            "data på serveren fra skærmen « Datatransparens » i appen."
        ),
        "h3_diagnostic": "2.5 Nedbruds- og diagnoserapporter (opt-in)",
        "p_diagnostic": (
            "Hvis du slår diagnose til i Indstillinger, sendes anonyme nedbrudsrapporter og "
            "ydelses-spor til Sentry. Ingen personlige oplysninger, placering eller indhold "
            "indgår. Diagnose er som standard slået fra."
        ),
        "h2_not_collected": "3. Data vi IKKE indsamler",
        "li_nc_email": "Navn, e-mailadresse eller telefonnummer",
        "li_nc_payment": "Finansielle eller betalings­oplysninger",
        "li_nc_health": "Sundheds- eller fitnessdata",
        "li_nc_contacts": "Kontakter, beskeder eller opkalds­logger",
        "li_nc_photos": "Fotos, videoer eller filer (adgang til kamera og foto­bibliotek bruges kun til kvitteringsskanning, du selv starter)",
        "li_nc_history": "Browser­historik",
        "li_nc_adid": "Enhedens reklame-id'er",
        "h2_third_parties": "4. Tredjeparts­tjenester",
        "p_third_parties_intro": "Appen kommunikerer med følgende tredjeparts-API'er:",
        "li_tk": "<strong>Tankerkönig</strong> (creativecommons.tankerkoenig.de) — tyske priser. Modtager: søge­koordinater, din API-nøgle.",
        "li_pc": "<strong>Prix Carburants</strong> (data.economie.gouv.fr) — franske priser. Modtager: søge­koordinater.",
        "li_it": "<strong>Italiensk pris-API</strong> (osservaprezzi.mise.gov.it) — italienske priser. Modtager: søge­koordinater.",
        "li_es": "<strong>Spansk pris-API</strong> (sedeaplicaciones.minetur.gob.es) — spanske priser. Modtager: søge­koordinater.",
        "li_at": "<strong>Spritpreisrechner</strong> (spritpreisrechner.at) — østrigske priser. Modtager: søge­koordinater.",
        "li_be": "<strong>FuelWatch</strong> (fuelwatch.be) — belgiske priser. Modtager: søge­koordinater.",
        "li_lu": "<strong>data.public.lu</strong> — luxembourgske priser. Modtager: søge­koordinater.",
        "li_ocm": "<strong>OpenChargeMap</strong> (api.openchargemap.io) — ladestationer. Modtager: søge­koordinater.",
        "li_nominatim": "<strong>Nominatim / OpenStreetMap</strong> (nominatim.openstreetmap.org) — geokodning. Modtager: søgetekst eller koordinater.",
        "li_osm": "<strong>OpenStreetMap tile-servere</strong> (tile.openstreetmap.org) — kort-tiles. Modtager: tile-koordinater.",
        "li_supabase": "<strong>Supabase</strong> (kun hvis TankSync er aktiv) — backend til cloud-synk.",
        "li_sentry": "<strong>Sentry</strong> (kun hvis diagnose er aktiv) — anonyme nedbruds- og ydelses­rapporter.",
        "p_third_parties_outro": (
            "Hver udbyder har sin egen privatlivspolitik. Vi anbefaler, at du gennemgår dem. "
            "Appen deler ikke data mellem disse udbydere."
        ),
        "h2_security": "5. Datasikkerhed",
        "li_sec_https": "Al netværks­kommunikation bruger HTTPS (TLS-kryptering under overførsel).",
        "li_sec_keystore": "API-nøgler gemmes i platformens native krypterede lager (Android Keystore / iOS Keychain).",
        "li_sec_local": "Lokale data gemmes på din enhed via Hive.",
        "li_sec_silent": "Ingen data sendes til nogen server, medmindre du selv starter en søgning eller aktiverer TankSync / diagnose.",
        "h2_rights": "6. Dine rettigheder",
        "p_rights_intro": "Du har ret til at:",
        "li_r_access": "<strong>Få adgang</strong> — se alle lokalt lagrede data i appens Lager-sektion.",
        "li_r_export": "<strong>Eksportere</strong> — eksportere dine TankSync-data som JSON fra skærmen Datatransparens.",
        "li_r_delete": "<strong>Slette</strong> — slette alle lokale data via Indstillinger → Slet alle data; slette alle server­data via TankSync → Datatransparens → Slet alt.",
        "li_r_withdraw": "<strong>Trække samtykke tilbage</strong> — tilbagekalde placerings­tilladelsen i enhedens indstillinger eller slå TankSync / diagnose fra når som helst.",
        "h2_children": "7. Børns privatliv",
        "p_children": (
            "Appen er ikke rettet mod børn under 13 år. Vi indsamler ikke bevidst personlige "
            "oplysninger fra børn."
        ),
        "h2_changes": "8. Ændringer i denne politik",
        "p_changes": (
            "Vi kan opdatere denne politik fra tid til anden. Ændringer offentliggøres på denne "
            "URL med en opdateret dato. Fortsat brug af appen udgør accept af den opdaterede "
            "politik."
        ),
        "h2_contact": "9. Kontakt",
        "contact_dev_label": "Udvikler",
        "contact_email_label": "E-mail",
        "contact_source_label": "Kildekode",
        "lang_switcher_label": "Tilgængelige sprog:",
    },
    # Polish
    "pl": {
        "html_lang": "pl",
        "page_title": "Sparkilo — Polityka prywatności",
        "h1": "Polityka prywatności",
        "meta_app": "Sparkilo (de.tankstellen.tankstellen w iOS, de.tankstellen.fuelprices w Androidzie)",
        "meta_last_updated": "Ostatnia aktualizacja: 9 maja 2026",
        "h2_overview": "1. Omówienie",
        "p_overview": (
            "Sparkilo (wcześniej Fuel Prices Europe & More) to bezpłatna aplikacja open source "
            "do porównywania cen paliw i punktów ładowania pojazdów elektrycznych. Zaprojektowano "
            "ją w architekturze <strong>local-first, szanującej prywatność</strong>. Bez reklam, "
            "bez pikseli śledzących, bez identyfikatorów reklamowych."
        ),
        "h2_collected": "2. Wykorzystywane dane",
        "h3_location": "2.1 Przybliżona lokalizacja",
        "p_location": (
            "Po przyznaniu uprawnienia do lokalizacji aplikacja odczytuje Twoją przybliżoną "
            "pozycję, by znaleźć pobliskie stacje paliw i punkty ładowania. Współrzędne są "
            "wysyłane do interfejsów API stron trzecich (zob. sekcja 4) jako część zapytania. "
            "Twoja lokalizacja <strong>nie jest przechowywana na żadnym z naszych serwerów</strong> "
            "i nigdy nie służy do śledzenia ani profilowania."
        ),
        "h3_apikey": "2.2 Klucze API podawane przez Ciebie",
        "p_apikey": (
            "Jeśli podasz własny klucz API (np. Tankerkönig), zostanie on zapisany lokalnie w "
            "szyfrowanym magazynie (Android Keystore / iOS Keychain). Klucz wysyłany jest "
            "wyłącznie do odpowiedniego dostawcy API — nigdy do nas ani do osób trzecich."
        ),
        "h3_local": "2.3 Ulubione, profile i ustawienia",
        "p_local": (
            "Twoje ulubione, profile wyszukiwania, preferencje paliw i ustawienia aplikacji "
            "przechowywane są lokalnie na urządzeniu w bazie Hive."
        ),
        "h3_sync": "2.4 TankSync (opcjonalna synchronizacja w chmurze)",
        "p_sync_intro": "Po włączeniu TankSync tworzone jest anonimowe konto w Supabase. Synchronizowane są:",
        "li_sync_id": "Anonimowy identyfikator użytkownika (UUID — bez e-maila, bez imienia)",
        "li_sync_fav": "Identyfikatory ulubionych stacji",
        "li_sync_alerts": "Konfiguracje alertów cenowych",
        "li_sync_reports": "Społecznościowe zgłoszenia cen (ID stacji, rodzaj paliwa, cena, znacznik czasu)",
        "p_sync_outro": (
            "TankSync jest opcjonalny i domyślnie wyłączony. Możesz przeglądać, eksportować i "
            "usuwać wszystkie dane po stronie serwera z ekranu « Przejrzystość danych » w aplikacji."
        ),
        "h3_diagnostic": "2.5 Raporty awarii i diagnostyki (opt-in)",
        "p_diagnostic": (
            "Po włączeniu diagnostyki w Ustawieniach do Sentry wysyłane są anonimowe raporty "
            "awarii i ślady wydajności. Nie są przekazywane żadne dane osobowe, lokalizacja "
            "ani treści. Diagnostyka jest domyślnie wyłączona."
        ),
        "h2_not_collected": "3. Dane, których NIE zbieramy",
        "li_nc_email": "Imię i nazwisko, adres e-mail lub numer telefonu",
        "li_nc_payment": "Dane finansowe lub płatnicze",
        "li_nc_health": "Dane zdrowotne lub fitness",
        "li_nc_contacts": "Kontakty, wiadomości lub rejestry połączeń",
        "li_nc_photos": "Zdjęcia, filmy lub pliki (dostęp do aparatu i biblioteki zdjęć jest używany tylko do skanowania paragonów, gdy Ty go uruchamiasz)",
        "li_nc_history": "Historia przeglądania",
        "li_nc_adid": "Identyfikatory reklamowe urządzenia",
        "h2_third_parties": "4. Usługi stron trzecich",
        "p_third_parties_intro": "Aplikacja komunikuje się z następującymi interfejsami API stron trzecich:",
        "li_tk": "<strong>Tankerkönig</strong> (creativecommons.tankerkoenig.de) — ceny niemieckie. Otrzymuje: współrzędne wyszukiwania, Twój klucz API.",
        "li_pc": "<strong>Prix Carburants</strong> (data.economie.gouv.fr) — ceny francuskie. Otrzymuje: współrzędne wyszukiwania.",
        "li_it": "<strong>Włoskie API cen</strong> (osservaprezzi.mise.gov.it) — ceny włoskie. Otrzymuje: współrzędne wyszukiwania.",
        "li_es": "<strong>Hiszpańskie API cen</strong> (sedeaplicaciones.minetur.gob.es) — ceny hiszpańskie. Otrzymuje: współrzędne wyszukiwania.",
        "li_at": "<strong>Spritpreisrechner</strong> (spritpreisrechner.at) — ceny austriackie. Otrzymuje: współrzędne wyszukiwania.",
        "li_be": "<strong>FuelWatch</strong> (fuelwatch.be) — ceny belgijskie. Otrzymuje: współrzędne wyszukiwania.",
        "li_lu": "<strong>data.public.lu</strong> — ceny luksemburskie. Otrzymuje: współrzędne wyszukiwania.",
        "li_ocm": "<strong>OpenChargeMap</strong> (api.openchargemap.io) — punkty ładowania. Otrzymuje: współrzędne wyszukiwania.",
        "li_nominatim": "<strong>Nominatim / OpenStreetMap</strong> (nominatim.openstreetmap.org) — geokodowanie. Otrzymuje: tekst lub współrzędne wyszukiwania.",
        "li_osm": "<strong>Serwery kafelków OpenStreetMap</strong> (tile.openstreetmap.org) — kafelki mapy. Otrzymuje: współrzędne kafelka.",
        "li_supabase": "<strong>Supabase</strong> (tylko gdy TankSync jest włączony) — backend synchronizacji w chmurze.",
        "li_sentry": "<strong>Sentry</strong> (tylko gdy diagnostyka jest włączona) — anonimowe raporty awarii i wydajności.",
        "p_third_parties_outro": (
            "Każdy dostawca ma własną politykę prywatności. Zachęcamy do zapoznania się z nimi. "
            "Aplikacja nie udostępnia danych pomiędzy tymi dostawcami."
        ),
        "h2_security": "5. Bezpieczeństwo danych",
        "li_sec_https": "Cała komunikacja sieciowa odbywa się przez HTTPS (szyfrowanie TLS w transporcie).",
        "li_sec_keystore": "Klucze API są przechowywane w natywnym, szyfrowanym magazynie platformy (Android Keystore / iOS Keychain).",
        "li_sec_local": "Dane lokalne są przechowywane na Twoim urządzeniu w bazie Hive.",
        "li_sec_silent": "Żadne dane nie są wysyłane do serwerów, dopóki nie uruchomisz wyszukiwania ani nie włączysz TankSync / diagnostyki.",
        "h2_rights": "6. Twoje prawa",
        "p_rights_intro": "Masz prawo do:",
        "li_r_access": "<strong>Dostępu</strong> — przeglądania wszystkich lokalnie zapisanych danych w sekcji Pamięć w aplikacji.",
        "li_r_export": "<strong>Eksportu</strong> — eksportu danych TankSync w formacie JSON z ekranu Przejrzystość danych.",
        "li_r_delete": "<strong>Usunięcia</strong> — usunięcia wszystkich danych lokalnych przez Ustawienia → Usuń wszystkie dane; usunięcia wszystkich danych po stronie serwera przez TankSync → Przejrzystość danych → Usuń wszystko.",
        "li_r_withdraw": "<strong>Wycofania zgody</strong> — odebranie uprawnienia do lokalizacji w ustawieniach urządzenia lub wyłączenie TankSync / diagnostyki w dowolnej chwili.",
        "h2_children": "7. Prywatność dzieci",
        "p_children": (
            "Aplikacja nie jest skierowana do dzieci poniżej 13 roku życia. Świadomie nie "
            "zbieramy danych osobowych od dzieci."
        ),
        "h2_changes": "8. Zmiany w niniejszej polityce",
        "p_changes": (
            "Co pewien czas możemy aktualizować tę politykę. Zmiany będą publikowane pod tym "
            "adresem URL z aktualną datą. Dalsze korzystanie z aplikacji oznacza akceptację "
            "zaktualizowanej polityki."
        ),
        "h2_contact": "9. Kontakt",
        "contact_dev_label": "Programista",
        "contact_email_label": "E-mail",
        "contact_source_label": "Kod źródłowy",
        "lang_switcher_label": "Dostępne języki:",
    },
    # Slovenian
    "sl": {
        "html_lang": "sl",
        "page_title": "Sparkilo — Pravilnik o zasebnosti",
        "h1": "Pravilnik o zasebnosti",
        "meta_app": "Sparkilo (de.tankstellen.tankstellen v iOS-u, de.tankstellen.fuelprices v Androidu)",
        "meta_last_updated": "Zadnja posodobitev: 9. maj 2026",
        "h2_overview": "1. Pregled",
        "p_overview": (
            "Sparkilo (prej Fuel Prices Europe & More) je brezplačna odprtokodna aplikacija za "
            "primerjavo cen goriv in polnilnih postaj za električna vozila. Zgrajena je po "
            "<strong>local-first, zasebnost spoštujočem</strong> načelu. Brez oglasov, brez "
            "sledilnih pikslov, brez oglaševalskih ID-jev."
        ),
        "h2_collected": "2. Podatki, ki jih uporabljamo",
        "h3_location": "2.1 Približna lokacija",
        "p_location": (
            "Ko dovolite dostop do lokacije, aplikacija prebere vaš približni položaj, da poišče "
            "bližnje črpalke in polnilne postaje. Koordinate se kot del poizvedbe pošljejo "
            "API-jem tretjih oseb (glejte razdelek 4). Vaša lokacija "
            "<strong>se ne shrani na noben naš strežnik</strong> in se nikoli ne uporablja za "
            "sledenje ali profiliranje."
        ),
        "h3_apikey": "2.2 API ključi, ki jih posredujete sami",
        "p_apikey": (
            "Če posredujete svoj API ključ (npr. Tankerkönig), je shranjen lokalno v šifriranem "
            "shranjevalniku (Android Keystore / iOS Keychain). Ključ se pošlje samo ustreznemu "
            "ponudniku API-ja, nikoli nam ali tretjim osebam."
        ),
        "h3_local": "2.3 Priljubljene, profili in nastavitve",
        "p_local": (
            "Vaše priljubljene, iskalni profili, nastavitve goriv in nastavitve aplikacije se "
            "shranjujejo lokalno na vašo napravo v zbirko Hive."
        ),
        "h3_sync": "2.4 TankSync (neobvezna sinhronizacija v oblaku)",
        "p_sync_intro": "Če omogočite TankSync, se prek storitve Supabase ustvari anonimni račun. Sinhronizirani podatki:",
        "li_sync_id": "Anonimni ID uporabnika (UUID — brez e-pošte ali imena)",
        "li_sync_fav": "ID-ji priljubljenih črpalk",
        "li_sync_alerts": "Nastavitve cenovnih opozoril",
        "li_sync_reports": "Skupnostni podatki o cenah (ID črpalke, vrsta goriva, cena, časovni žig)",
        "p_sync_outro": (
            "TankSync je neobvezen in privzeto izklopljen. Vse podatke na strežniku si lahko "
            "ogledate, izvozite in izbrišete iz zaslona « Preglednost podatkov » znotraj aplikacije."
        ),
        "h3_diagnostic": "2.5 Poročila o sesutjih in diagnostika (po izbiri)",
        "p_diagnostic": (
            "Če v Nastavitvah omogočite diagnostiko, se v Sentry pošljejo anonimna poročila o "
            "sesutjih in sledi delovanja. Vključenih ni nobenih osebnih podatkov, lokacije ali "
            "vsebine. Diagnostika je privzeto izklopljena."
        ),
        "h2_not_collected": "3. Podatki, ki jih NE zbiramo",
        "li_nc_email": "Ime, e-poštni naslov ali telefonsko številko",
        "li_nc_payment": "Finančne ali plačilne podatke",
        "li_nc_health": "Zdravstvene ali fitnes podatke",
        "li_nc_contacts": "Stike, sporočila ali dnevnike klicev",
        "li_nc_photos": "Fotografije, video posnetke ali datoteke (dostop do kamere in galerije se uporablja le za skeniranje računov, ki ga sami sprožite)",
        "li_nc_history": "Zgodovino brskanja",
        "li_nc_adid": "Oglaševalske identifikatorje naprave",
        "h2_third_parties": "4. Storitve tretjih oseb",
        "p_third_parties_intro": "Aplikacija komunicira z naslednjimi API-ji tretjih oseb:",
        "li_tk": "<strong>Tankerkönig</strong> (creativecommons.tankerkoenig.de) — nemške cene. Prejme: koordinate iskanja, vaš API ključ.",
        "li_pc": "<strong>Prix Carburants</strong> (data.economie.gouv.fr) — francoske cene. Prejme: koordinate iskanja.",
        "li_it": "<strong>Italijanski API cen</strong> (osservaprezzi.mise.gov.it) — italijanske cene. Prejme: koordinate iskanja.",
        "li_es": "<strong>Španski API cen</strong> (sedeaplicaciones.minetur.gob.es) — španske cene. Prejme: koordinate iskanja.",
        "li_at": "<strong>Spritpreisrechner</strong> (spritpreisrechner.at) — avstrijske cene. Prejme: koordinate iskanja.",
        "li_be": "<strong>FuelWatch</strong> (fuelwatch.be) — belgijske cene. Prejme: koordinate iskanja.",
        "li_lu": "<strong>data.public.lu</strong> — luksemburške cene. Prejme: koordinate iskanja.",
        "li_ocm": "<strong>OpenChargeMap</strong> (api.openchargemap.io) — polnilne postaje. Prejme: koordinate iskanja.",
        "li_nominatim": "<strong>Nominatim / OpenStreetMap</strong> (nominatim.openstreetmap.org) — geokodiranje. Prejme: iskalno besedilo ali koordinate.",
        "li_osm": "<strong>Strežniki ploščic OpenStreetMap</strong> (tile.openstreetmap.org) — zemljevidne ploščice. Prejme: koordinate ploščice.",
        "li_supabase": "<strong>Supabase</strong> (samo če je TankSync omogočen) — zaledje za sinhronizacijo v oblaku.",
        "li_sentry": "<strong>Sentry</strong> (samo če je diagnostika omogočena) — anonimna poročila o sesutjih in delovanju.",
        "p_third_parties_outro": (
            "Vsak ponudnik ima svoj pravilnik o zasebnosti. Priporočamo, da jih preberete. "
            "Aplikacija med temi ponudniki ne deli podatkov."
        ),
        "h2_security": "5. Varnost podatkov",
        "li_sec_https": "Vsa omrežna komunikacija poteka prek HTTPS (TLS šifriranje med prenosom).",
        "li_sec_keystore": "API ključi se shranjujejo v platformi lastnem šifriranem shranjevalniku (Android Keystore / iOS Keychain).",
        "li_sec_local": "Lokalni podatki se shranjujejo na vaši napravi prek Hive.",
        "li_sec_silent": "Nobeni podatki se ne pošiljajo na strežnik, razen če sami sprožite iskanje ali omogočite TankSync / diagnostiko.",
        "h2_rights": "6. Vaše pravice",
        "p_rights_intro": "Imate pravico do:",
        "li_r_access": "<strong>Vpogleda</strong> — vse lokalno shranjene podatke si lahko ogledate v razdelku Shramba znotraj aplikacije.",
        "li_r_export": "<strong>Izvoza</strong> — podatke TankSync lahko izvozite v JSON s zaslona Preglednost podatkov.",
        "li_r_delete": "<strong>Izbrisa</strong> — vse lokalne podatke izbrišete prek Nastavitve → Izbriši vse podatke; vse strežniške podatke prek TankSync → Preglednost podatkov → Izbriši vse.",
        "li_r_withdraw": "<strong>Preklica privolitve</strong> — preklicati dovoljenje za lokacijo v sistemskih nastavitvah ali kadar koli onemogočiti TankSync / diagnostiko.",
        "h2_children": "7. Zasebnost otrok",
        "p_children": (
            "Aplikacija ni namenjena otrokom, mlajšim od 13 let. Zavestno ne zbiramo osebnih "
            "podatkov otrok."
        ),
        "h2_changes": "8. Spremembe tega pravilnika",
        "p_changes": (
            "Pravilnik lahko občasno posodobimo. Spremembe bomo objavili na tem URL-ju z "
            "ažurnim datumom. Z nadaljnjo uporabo aplikacije se strinjate s posodobljenim "
            "pravilnikom."
        ),
        "h2_contact": "9. Kontakt",
        "contact_dev_label": "Razvijalec",
        "contact_email_label": "E-pošta",
        "contact_source_label": "Izvorna koda",
        "lang_switcher_label": "Razpoložljivi jeziki:",
    },
    # Korean
    "ko": {
        "html_lang": "ko",
        "page_title": "Sparkilo — 개인정보 처리방침",
        "h1": "개인정보 처리방침",
        "meta_app": "Sparkilo (iOS의 de.tankstellen.tankstellen, Android의 de.tankstellen.fuelprices)",
        "meta_last_updated": "최종 업데이트: 2026년 5월 9일",
        "h2_overview": "1. 개요",
        "p_overview": (
            "Sparkilo(이전 명칭: Fuel Prices Europe & More)는 무료 오픈소스 연료 및 전기차 충전 가격 비교 앱입니다. "
            "<strong>로컬 우선, 개인정보를 존중하는</strong> 아키텍처로 설계되었습니다. 광고도, 추적 픽셀도, "
            "광고 식별자도 사용하지 않습니다."
        ),
        "h2_collected": "2. 사용하는 데이터",
        "h3_location": "2.1 대략적인 위치",
        "p_location": (
            "위치 권한을 허용하면 앱은 근처 주유소와 충전소를 찾기 위해 대략적인 위치를 읽습니다. "
            "좌표는 검색의 일부로 제3자 API(섹션 4 참조)에 전송됩니다. 위치 정보는 "
            "<strong>당사가 운영하는 어떤 서버에도 저장되지 않으며</strong> 추적이나 프로파일링에 "
            "사용되지 않습니다."
        ),
        "h3_apikey": "2.2 사용자가 제공하는 API 키",
        "p_apikey": (
            "사용자가 직접 API 키(예: Tankerkönig)를 제공하면, 해당 키는 암호화된 로컬 저장소"
            "(Android Keystore / iOS Keychain)에 저장됩니다. 키는 해당 API 제공자에게만 전송되며, "
            "당사나 제3자에게는 전송되지 않습니다."
        ),
        "h3_local": "2.3 즐겨찾기, 프로필 및 설정",
        "p_local": (
            "즐겨찾기, 검색 프로필, 연료 환경설정 및 앱 설정은 임베디드 로컬 데이터베이스인 Hive를 통해 "
            "기기에 로컬로 저장됩니다."
        ),
        "h3_sync": "2.4 TankSync(선택적 클라우드 동기화)",
        "p_sync_intro": "TankSync를 활성화하면 Supabase를 통해 익명 계정이 생성됩니다. 동기화되는 데이터:",
        "li_sync_id": "익명 사용자 ID(UUID — 이메일 또는 이름 없음)",
        "li_sync_fav": "즐겨찾는 주유소 ID",
        "li_sync_alerts": "가격 알림 구성",
        "li_sync_reports": "커뮤니티 가격 보고(주유소 ID, 연료 종류, 가격, 타임스탬프)",
        "p_sync_outro": (
            "TankSync는 선택사항이며 기본적으로 비활성화되어 있습니다. 앱 내 « 데이터 투명성 » 화면에서 "
            "모든 서버 측 데이터를 확인, 내보내기 및 삭제할 수 있습니다."
        ),
        "h3_diagnostic": "2.5 충돌 및 진단 보고서(옵트인)",
        "p_diagnostic": (
            "설정에서 진단 보고를 활성화하면 익명 충돌 보고서와 성능 추적이 Sentry로 전송됩니다. "
            "개인 식별 정보, 위치 또는 콘텐츠는 포함되지 않습니다. 진단 보고는 기본적으로 꺼져 있습니다."
        ),
        "h2_not_collected": "3. 수집하지 않는 데이터",
        "li_nc_email": "이름, 이메일 주소 또는 전화번호",
        "li_nc_payment": "금융 또는 결제 정보",
        "li_nc_health": "건강 또는 피트니스 데이터",
        "li_nc_contacts": "연락처, 메시지 또는 통화 기록",
        "li_nc_photos": "사진, 동영상 또는 파일(카메라 및 사진 라이브러리 접근은 사용자가 직접 시작한 영수증 스캔에만 사용됨)",
        "li_nc_history": "브라우저 기록",
        "li_nc_adid": "기기 광고 식별자",
        "h2_third_parties": "4. 제3자 서비스",
        "p_third_parties_intro": "앱은 다음 제3자 API와 통신합니다:",
        "li_tk": "<strong>Tankerkönig</strong>(creativecommons.tankerkoenig.de) — 독일 가격. 수신: 검색 좌표, 사용자 API 키.",
        "li_pc": "<strong>Prix Carburants</strong>(data.economie.gouv.fr) — 프랑스 가격. 수신: 검색 좌표.",
        "li_it": "<strong>이탈리아 가격 API</strong>(osservaprezzi.mise.gov.it) — 이탈리아 가격. 수신: 검색 좌표.",
        "li_es": "<strong>스페인 가격 API</strong>(sedeaplicaciones.minetur.gob.es) — 스페인 가격. 수신: 검색 좌표.",
        "li_at": "<strong>Spritpreisrechner</strong>(spritpreisrechner.at) — 오스트리아 가격. 수신: 검색 좌표.",
        "li_be": "<strong>FuelWatch</strong>(fuelwatch.be) — 벨기에 가격. 수신: 검색 좌표.",
        "li_lu": "<strong>data.public.lu</strong> — 룩셈부르크 가격. 수신: 검색 좌표.",
        "li_ocm": "<strong>OpenChargeMap</strong>(api.openchargemap.io) — 전기차 충전소. 수신: 검색 좌표.",
        "li_nominatim": "<strong>Nominatim / OpenStreetMap</strong>(nominatim.openstreetmap.org) — 지오코딩. 수신: 검색 텍스트 또는 좌표.",
        "li_osm": "<strong>OpenStreetMap 타일 서버</strong>(tile.openstreetmap.org) — 지도 타일. 수신: 타일 좌표.",
        "li_supabase": "<strong>Supabase</strong>(TankSync 활성화 시에만) — 클라우드 동기화 백엔드.",
        "li_sentry": "<strong>Sentry</strong>(진단 보고 활성화 시에만) — 익명 충돌 및 성능 보고서.",
        "p_third_parties_outro": (
            "각 제공자는 자체 개인정보 처리방침을 보유합니다. 검토하시기 바랍니다. 앱은 이러한 "
            "제공자 간에 데이터를 공유하지 않습니다."
        ),
        "h2_security": "5. 데이터 보안",
        "li_sec_https": "모든 네트워크 통신은 HTTPS(전송 중 TLS 암호화)를 사용합니다.",
        "li_sec_keystore": "API 키는 플랫폼 기본 암호화 저장소(Android Keystore / iOS Keychain)에 저장됩니다.",
        "li_sec_local": "로컬 데이터는 Hive를 통해 기기에 저장됩니다.",
        "li_sec_silent": "사용자가 검색을 시작하거나 TankSync / 진단을 활성화하지 않는 한 어떤 서버에도 데이터가 전송되지 않습니다.",
        "h2_rights": "6. 사용자의 권리",
        "p_rights_intro": "사용자는 다음 권리를 갖습니다:",
        "li_r_access": "<strong>접근</strong> — 앱의 저장 공간 섹션에서 로컬에 저장된 모든 데이터를 확인할 수 있습니다.",
        "li_r_export": "<strong>내보내기</strong> — 데이터 투명성 화면에서 TankSync 데이터를 JSON으로 내보낼 수 있습니다.",
        "li_r_delete": "<strong>삭제</strong> — 설정 → 모든 데이터 삭제로 모든 로컬 데이터를 삭제하고, TankSync → 데이터 투명성 → 모두 삭제로 모든 서버 데이터를 삭제할 수 있습니다.",
        "li_r_withdraw": "<strong>동의 철회</strong> — 기기 설정에서 위치 권한을 취소하거나 언제든 TankSync / 진단을 비활성화할 수 있습니다.",
        "h2_children": "7. 아동 개인정보",
        "p_children": (
            "이 앱은 13세 미만 아동을 대상으로 하지 않습니다. 당사는 아동으로부터 개인정보를 "
            "고의로 수집하지 않습니다."
        ),
        "h2_changes": "8. 정책 변경",
        "p_changes": (
            "당사는 이 정책을 수시로 업데이트할 수 있습니다. 변경사항은 업데이트된 날짜와 함께 "
            "이 URL에 게시됩니다. 앱을 계속 사용하는 것은 업데이트된 정책에 대한 동의로 간주됩니다."
        ),
        "h2_contact": "9. 연락처",
        "contact_dev_label": "개발자",
        "contact_email_label": "이메일",
        "contact_source_label": "소스 코드",
        "lang_switcher_label": "지원 언어:",
    },
}


def render(lang: str) -> str:
    t = TRANSLATIONS[lang]
    css_path = "assets/styles.css" if lang == "en" else "../assets/styles.css"
    lang_links = " ".join(
        f'<a href="{LOCALE_URLS[ln]}">{LOCALE_LABELS[ln]}</a>'
        for ln in TRANSLATIONS.keys()
    )
    return textwrap.dedent(f"""\
        <!DOCTYPE html>
        <html lang="{t['html_lang']}">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>{html.escape(t['page_title'])}</title>
          <link rel="stylesheet" href="{css_path}">
        </head>
        <body>

        <h1>{t['h1']}</h1>
        <p class="meta">{t['meta_app']} &mdash; {t['meta_last_updated']}</p>
        <p class="langs">{t['lang_switcher_label']} {lang_links}</p>

        <h2>{t['h2_overview']}</h2>
        <p>{t['p_overview']}</p>

        <h2>{t['h2_collected']}</h2>

        <h3>{t['h3_location']}</h3>
        <p>{t['p_location']}</p>

        <h3>{t['h3_apikey']}</h3>
        <p>{t['p_apikey']}</p>

        <h3>{t['h3_local']}</h3>
        <p>{t['p_local']}</p>

        <h3>{t['h3_sync']}</h3>
        <p>{t['p_sync_intro']}</p>
        <ul>
          <li>{t['li_sync_id']}</li>
          <li>{t['li_sync_fav']}</li>
          <li>{t['li_sync_alerts']}</li>
          <li>{t['li_sync_reports']}</li>
        </ul>
        <p>{t['p_sync_outro']}</p>

        <h3>{t['h3_diagnostic']}</h3>
        <p>{t['p_diagnostic']}</p>

        <h2>{t['h2_not_collected']}</h2>
        <ul>
          <li>{t['li_nc_email']}</li>
          <li>{t['li_nc_payment']}</li>
          <li>{t['li_nc_health']}</li>
          <li>{t['li_nc_contacts']}</li>
          <li>{t['li_nc_photos']}</li>
          <li>{t['li_nc_history']}</li>
          <li>{t['li_nc_adid']}</li>
        </ul>

        <h2>{t['h2_third_parties']}</h2>
        <p>{t['p_third_parties_intro']}</p>
        <ul>
          <li>{t['li_tk']}</li>
          <li>{t['li_pc']}</li>
          <li>{t['li_it']}</li>
          <li>{t['li_es']}</li>
          <li>{t['li_at']}</li>
          <li>{t['li_be']}</li>
          <li>{t['li_lu']}</li>
          <li>{t['li_ocm']}</li>
          <li>{t['li_nominatim']}</li>
          <li>{t['li_osm']}</li>
          <li>{t['li_supabase']}</li>
          <li>{t['li_sentry']}</li>
        </ul>
        <p>{t['p_third_parties_outro']}</p>

        <h2>{t['h2_security']}</h2>
        <ul>
          <li>{t['li_sec_https']}</li>
          <li>{t['li_sec_keystore']}</li>
          <li>{t['li_sec_local']}</li>
          <li>{t['li_sec_silent']}</li>
        </ul>

        <h2>{t['h2_rights']}</h2>
        <p>{t['p_rights_intro']}</p>
        <ul>
          <li>{t['li_r_access']}</li>
          <li>{t['li_r_export']}</li>
          <li>{t['li_r_delete']}</li>
          <li>{t['li_r_withdraw']}</li>
        </ul>

        <h2>{t['h2_children']}</h2>
        <p>{t['p_children']}</p>

        <h2>{t['h2_changes']}</h2>
        <p>{t['p_changes']}</p>

        <h2>{t['h2_contact']}</h2>
        <div class="contact">
          <p><strong>{t['contact_dev_label']}:</strong> Florian DITTGEN</p>
          <p><strong>{t['contact_email_label']}:</strong> <a href="mailto:fdittgen@gmail.com">fdittgen@gmail.com</a></p>
          <p><strong>{t['contact_source_label']}:</strong> <a href="https://github.com/fdittgen-png/tankstellen">github.com/fdittgen-png/tankstellen</a></p>
        </div>

        </body>
        </html>
    """)


def main() -> None:
    for lang in TRANSLATIONS:
        out_dir = OUT_ROOT if lang == "en" else OUT_ROOT / lang
        out_dir.mkdir(parents=True, exist_ok=True)
        out_file = out_dir / "index.html"
        out_file.write_text(render(lang), encoding="utf-8")
        rel = out_file.relative_to(REPO_ROOT)
        print(f"  wrote {rel}")
    print(f"Done. {len(TRANSLATIONS)} locales generated.")


if __name__ == "__main__":
    main()
