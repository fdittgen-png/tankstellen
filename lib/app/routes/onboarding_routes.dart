import 'package:go_router/go_router.dart';

import '../../features/consent/presentation/screens/gdpr_consent_screen.dart';
import '../../features/setup/presentation/screens/onboarding_wizard_screen.dart';

/// Routes that gate the app at first launch — GDPR consent and the onboarding
/// wizard. Sit at the top of the route table so the redirect logic in
/// [routerProvider] can deep-link straight to either of them.
List<RouteBase> get onboardingRoutes => [
      GoRoute(
        path: '/consent',
        builder: (context, state) => const GdprConsentScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const OnboardingWizardScreen(),
      ),
    ];
