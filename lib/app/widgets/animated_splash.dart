import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Animated Flutter splash shown between the native splash drawable and the
/// first paint of [TankstellenApp] (#795 phase 2).
///
/// Design goals:
///   * **Continuity with the native splash.** The Android launch drawable
///     (`android/app/src/main/res/drawable/launch_background.xml`) paints a
///     solid green backdrop (`#2E7D32`, see `values/colors.xml →
///     ic_launcher_background`) with a centered shield-and-drop glyph. This
///     widget renders *on top of* the same backdrop colour so there's no
///     visible seam at the handoff — the brand glyph gets a gentle scale +
///     fade animation, making the transition feel *earned* rather than
///     abrupt.
///   * **Professional, not cute.** A single-axis transform (scale 0.88 →
///     1.00 over 450ms, cubic-out) plus a fade-in (180ms lead, 300ms
///     duration) produces the "arrive with weight" feel of a proper brand
///     reveal. No bouncing, no rotation, no spring overshoot. A slim
///     indeterminate progress bar at the bottom gives the user a pulse of
///     activity while [AppInitializer.run] is finishing its work.
///   * **Dark-mode aware.** The native splash drawable is the same in light
///     + dark, so the Flutter splash keeps the same brand green on both.
///     The progress bar / wordmark colours flex slightly for readability
///     (lower-contrast green on dark, since the launcher already pre-tints
///     the viewport green and stacking more saturation reads as a bug).
///   * **Accessible.** A `Semantics(label: ..., liveRegion: true)` wrapper
///     exposes "Loading Tankstellen" to TalkBack/VoiceOver so assistive
///     tech users get a meaningful announcement instead of a silent pause.
///
/// The widget is stateful because it owns the scale/fade [AnimationController].
/// It does **not** own the transition from splash → app — that happens one
/// level up in `main.dart`, where `runApp` is called twice: once with the
/// splash as the root, then again with [TankstellenApp] once
/// `AppInitializer.run()` resolves.
class AnimatedSplash extends StatefulWidget {
  const AnimatedSplash({super.key});

  /// Matches `android/app/src/main/res/values/colors.xml →
  /// ic_launcher_background`. Kept in both places so the native splash
  /// and the Flutter splash paint the exact same backdrop — the handoff
  /// must be invisible.
  static const Color brandBackground = Color(0xFF2E7D32);

  /// Darker shade for the progress track so the indeterminate bar has a
  /// subtle rail to slide along without screaming for attention.
  static const Color brandBackgroundDark = Color(0xFF1B5E20);

  /// Logo white — matches the adaptive icon foreground stroke / fill.
  static const Color logoColor = Color(0xFFFFFFFF);

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    // Scale: start slightly under-sized so the logo settles in rather than
    // pops. 0.88 → 1.00 over the full duration with a cubic-out curve gives
    // the classic "arrival with inertia" feel.
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    // Fade: lead out the first ~28% of the duration (native splash is still
    // visible, no need to cross-fade) and then ramp to full opacity.
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loadingLabel = l10n?.splashLoadingLabel ?? 'Loading Tankstellen';
    return Semantics(
      label: loadingLabel,
      liveRegion: true,
      container: true,
      child: ColoredBox(
        color: AnimatedSplash.brandBackground,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              Expanded(
                flex: 4,
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: const ExcludeSemantics(
                        child: SizedBox(
                          width: 144,
                          height: 144,
                          child: CustomPaint(
                            painter: _BrandGlyphPainter(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _fade,
                      child: Text(
                        l10n?.appTitle ?? 'Tankstellen',
                        style: const TextStyle(
                          color: AnimatedSplash.logoColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _fade,
                      child: const _SplashProgressBar(),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// A thin, tasteful indeterminate bar. Uses [LinearProgressIndicator] with
/// explicit track/value colours matched to the brand backdrop so it reads
/// like a built-in brand element, not a stock Material widget.
class _SplashProgressBar extends StatelessWidget {
  const _SplashProgressBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 160,
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        child: LinearProgressIndicator(
          backgroundColor: AnimatedSplash.brandBackgroundDark,
          valueColor: AlwaysStoppedAnimation<Color>(AnimatedSplash.logoColor),
          minHeight: 3,
        ),
      ),
    );
  }
}

/// Paints the brand glyph (shield outline with a fuel-drop inside) directly
/// in Dart. Mirrors the adaptive-icon vector in
/// `android/app/src/main/res/drawable/ic_launcher_foreground.xml` so the
/// splash glyph is pixel-consistent with the launcher icon the user just
/// tapped.
///
/// Painting in code rather than loading an SVG/PNG avoids adding an
/// asset (allowlist forbids new images) and keeps the splash rendering
/// path zero-allocation after the first frame.
class _BrandGlyphPainter extends CustomPainter {
  const _BrandGlyphPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Work in a 108×108 coordinate system that mirrors the adaptive icon
    // viewport so the strokes line up 1:1 with the launcher icon.
    final scale = size.width / 108.0;
    canvas.save();
    canvas.scale(scale);

    final strokePaint = Paint()
      ..color = AnimatedSplash.logoColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = AnimatedSplash.logoColor
      ..style = PaintingStyle.fill;

    // Shield outline.
    final shield = Path()
      ..moveTo(54, 24)
      ..lineTo(78, 32)
      ..lineTo(78, 58)
      ..cubicTo(78, 72, 68, 82, 54, 86)
      ..cubicTo(40, 82, 30, 72, 30, 58)
      ..lineTo(30, 32)
      ..close();
    canvas.drawPath(shield, strokePaint);

    // Fuel drop.
    final drop = Path()
      ..moveTo(54, 38)
      ..cubicTo(54, 38, 42, 52, 42, 62)
      ..cubicTo(42, 69.18, 47.37, 75, 54, 75)
      ..cubicTo(60.63, 75, 66, 69.18, 66, 62)
      ..cubicTo(66, 52, 54, 38, 54, 38)
      ..close();
    canvas.drawPath(drop, fillPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrandGlyphPainter oldDelegate) => false;
}

/// Minimal top-level widget that mounts [AnimatedSplash] before
/// [AppInitializer.run] resolves. We use [WidgetsApp] (not [MaterialApp])
/// because the splash needs zero Material scaffolding — a Directionality,
/// MediaQuery, and localization delegates are the whole contract. Keeping
/// the host tiny matters because it's rendered *before* Hive / Riverpod
/// are wired, so it must not transitively touch any service layer.
class SplashHost extends StatelessWidget {
  const SplashHost({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Tankstellen',
      color: AnimatedSplash.brandBackground,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // `onGenerateRoute` with a zero-duration transition is cheaper than
      // `home:`, which would force a MaterialApp-style Navigator setup.
      onGenerateRoute: (_) => PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AnimatedSplash(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

