// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_form_widget_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthFormWidgetController)
final authFormWidgetControllerProvider = AuthFormWidgetControllerProvider._();

final class AuthFormWidgetControllerProvider
    extends $NotifierProvider<AuthFormWidgetController, AuthFormWidgetState> {
  AuthFormWidgetControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authFormWidgetControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authFormWidgetControllerHash();

  @$internal
  @override
  AuthFormWidgetController create() => AuthFormWidgetController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthFormWidgetState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthFormWidgetState>(value),
    );
  }
}

String _$authFormWidgetControllerHash() =>
    r'300aaeaf2755267997db20b83ed3bd4085da7544';

abstract class _$AuthFormWidgetController
    extends $Notifier<AuthFormWidgetState> {
  AuthFormWidgetState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AuthFormWidgetState, AuthFormWidgetState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthFormWidgetState, AuthFormWidgetState>,
              AuthFormWidgetState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
