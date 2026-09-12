// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'shell_bar_visibility.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the shell's bottom bar is swiped away (#4097).
///
/// Hiding it reveals the strip of content the bar was covering — bodies
/// already paint behind it since #4096 — and the round button stays
/// exactly where it is, so the one piece of chrome the user needs to get
/// the bar back is the one piece still on screen.
///
/// ## Never a trap
///
/// A hidden bar with no affordance is a dead end, so there are three
/// independent ways back and one of them is not a gesture:
///
///  1. an upward drag anywhere in the bottom strip,
///  2. a long-press on the round button,
///  3. the button's `Show navigation` semantics action, which switch
///     access and TalkBack reach without any gesture at all.
///
/// Tap keeps its current meaning, so nothing the user does today
/// changes.
///
/// The choice persists across launches — a user who wants the room
/// should not have to re-hide it every time — which is exactly why the
/// ways back have to be this redundant.

@ProviderFor(ShellBarHidden)
final shellBarHiddenProvider = ShellBarHiddenProvider._();

/// Whether the shell's bottom bar is swiped away (#4097).
///
/// Hiding it reveals the strip of content the bar was covering — bodies
/// already paint behind it since #4096 — and the round button stays
/// exactly where it is, so the one piece of chrome the user needs to get
/// the bar back is the one piece still on screen.
///
/// ## Never a trap
///
/// A hidden bar with no affordance is a dead end, so there are three
/// independent ways back and one of them is not a gesture:
///
///  1. an upward drag anywhere in the bottom strip,
///  2. a long-press on the round button,
///  3. the button's `Show navigation` semantics action, which switch
///     access and TalkBack reach without any gesture at all.
///
/// Tap keeps its current meaning, so nothing the user does today
/// changes.
///
/// The choice persists across launches — a user who wants the room
/// should not have to re-hide it every time — which is exactly why the
/// ways back have to be this redundant.
final class ShellBarHiddenProvider
    extends $NotifierProvider<ShellBarHidden, bool> {
  /// Whether the shell's bottom bar is swiped away (#4097).
  ///
  /// Hiding it reveals the strip of content the bar was covering — bodies
  /// already paint behind it since #4096 — and the round button stays
  /// exactly where it is, so the one piece of chrome the user needs to get
  /// the bar back is the one piece still on screen.
  ///
  /// ## Never a trap
  ///
  /// A hidden bar with no affordance is a dead end, so there are three
  /// independent ways back and one of them is not a gesture:
  ///
  ///  1. an upward drag anywhere in the bottom strip,
  ///  2. a long-press on the round button,
  ///  3. the button's `Show navigation` semantics action, which switch
  ///     access and TalkBack reach without any gesture at all.
  ///
  /// Tap keeps its current meaning, so nothing the user does today
  /// changes.
  ///
  /// The choice persists across launches — a user who wants the room
  /// should not have to re-hide it every time — which is exactly why the
  /// ways back have to be this redundant.
  ShellBarHiddenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shellBarHiddenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shellBarHiddenHash();

  @$internal
  @override
  ShellBarHidden create() => ShellBarHidden();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$shellBarHiddenHash() => r'fb911b8b5da46a575e9f570cf02b33639ca27ea0';

/// Whether the shell's bottom bar is swiped away (#4097).
///
/// Hiding it reveals the strip of content the bar was covering — bodies
/// already paint behind it since #4096 — and the round button stays
/// exactly where it is, so the one piece of chrome the user needs to get
/// the bar back is the one piece still on screen.
///
/// ## Never a trap
///
/// A hidden bar with no affordance is a dead end, so there are three
/// independent ways back and one of them is not a gesture:
///
///  1. an upward drag anywhere in the bottom strip,
///  2. a long-press on the round button,
///  3. the button's `Show navigation` semantics action, which switch
///     access and TalkBack reach without any gesture at all.
///
/// Tap keeps its current meaning, so nothing the user does today
/// changes.
///
/// The choice persists across launches — a user who wants the room
/// should not have to re-hide it every time — which is exactly why the
/// ways back have to be this redundant.

abstract class _$ShellBarHidden extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Whether the swipe-away coach mark has been shown (#4106).
///
/// Once ever, like the #1690 swipe-between-tabs hint: a gesture needs
/// introducing exactly one time, and a hint that returns is an
/// annoyance rather than help.

@ProviderFor(ShellSwipeCoachSeen)
final shellSwipeCoachSeenProvider = ShellSwipeCoachSeenProvider._();

/// Whether the swipe-away coach mark has been shown (#4106).
///
/// Once ever, like the #1690 swipe-between-tabs hint: a gesture needs
/// introducing exactly one time, and a hint that returns is an
/// annoyance rather than help.
final class ShellSwipeCoachSeenProvider
    extends $NotifierProvider<ShellSwipeCoachSeen, bool> {
  /// Whether the swipe-away coach mark has been shown (#4106).
  ///
  /// Once ever, like the #1690 swipe-between-tabs hint: a gesture needs
  /// introducing exactly one time, and a hint that returns is an
  /// annoyance rather than help.
  ShellSwipeCoachSeenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shellSwipeCoachSeenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shellSwipeCoachSeenHash();

  @$internal
  @override
  ShellSwipeCoachSeen create() => ShellSwipeCoachSeen();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$shellSwipeCoachSeenHash() =>
    r'5c7ececb81dcad55eae47f7e5d25ed0536321bd7';

/// Whether the swipe-away coach mark has been shown (#4106).
///
/// Once ever, like the #1690 swipe-between-tabs hint: a gesture needs
/// introducing exactly one time, and a hint that returns is an
/// annoyance rather than help.

abstract class _$ShellSwipeCoachSeen extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
