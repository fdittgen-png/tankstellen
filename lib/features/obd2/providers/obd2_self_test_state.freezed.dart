// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'obd2_self_test_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Obd2SelfTestStep {

 Obd2SelfTestStepId get id; Obd2SelfTestStepStatus get status; int? get latencyMs;/// #3555 — the layer's captured data (raw, locale-neutral transcript
/// line: firmware id, voltage, protocol name, PID count, live values).
 String? get detail;/// True while this step is the one currently executing — drives the
/// inline progress spinner. Exactly one step is `running` at a time.
 bool get running;
/// Create a copy of Obd2SelfTestStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Obd2SelfTestStepCopyWith<Obd2SelfTestStep> get copyWith => _$Obd2SelfTestStepCopyWithImpl<Obd2SelfTestStep>(this as Obd2SelfTestStep, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Obd2SelfTestStep&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.running, running) || other.running == running));
}


@override
int get hashCode => Object.hash(runtimeType,id,status,latencyMs,detail,running);

@override
String toString() {
  return 'Obd2SelfTestStep(id: $id, status: $status, latencyMs: $latencyMs, detail: $detail, running: $running)';
}


}

/// @nodoc
abstract mixin class $Obd2SelfTestStepCopyWith<$Res>  {
  factory $Obd2SelfTestStepCopyWith(Obd2SelfTestStep value, $Res Function(Obd2SelfTestStep) _then) = _$Obd2SelfTestStepCopyWithImpl;
@useResult
$Res call({
 Obd2SelfTestStepId id, Obd2SelfTestStepStatus status, int? latencyMs, String? detail, bool running
});




}
/// @nodoc
class _$Obd2SelfTestStepCopyWithImpl<$Res>
    implements $Obd2SelfTestStepCopyWith<$Res> {
  _$Obd2SelfTestStepCopyWithImpl(this._self, this._then);

  final Obd2SelfTestStep _self;
  final $Res Function(Obd2SelfTestStep) _then;

/// Create a copy of Obd2SelfTestStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? latencyMs = freezed,Object? detail = freezed,Object? running = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as Obd2SelfTestStepId,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Obd2SelfTestStepStatus,latencyMs: freezed == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int?,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Obd2SelfTestStep].
extension Obd2SelfTestStepPatterns on Obd2SelfTestStep {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Obd2SelfTestStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Obd2SelfTestStep() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Obd2SelfTestStep value)  $default,){
final _that = this;
switch (_that) {
case _Obd2SelfTestStep():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Obd2SelfTestStep value)?  $default,){
final _that = this;
switch (_that) {
case _Obd2SelfTestStep() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Obd2SelfTestStepId id,  Obd2SelfTestStepStatus status,  int? latencyMs,  String? detail,  bool running)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Obd2SelfTestStep() when $default != null:
return $default(_that.id,_that.status,_that.latencyMs,_that.detail,_that.running);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Obd2SelfTestStepId id,  Obd2SelfTestStepStatus status,  int? latencyMs,  String? detail,  bool running)  $default,) {final _that = this;
switch (_that) {
case _Obd2SelfTestStep():
return $default(_that.id,_that.status,_that.latencyMs,_that.detail,_that.running);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Obd2SelfTestStepId id,  Obd2SelfTestStepStatus status,  int? latencyMs,  String? detail,  bool running)?  $default,) {final _that = this;
switch (_that) {
case _Obd2SelfTestStep() when $default != null:
return $default(_that.id,_that.status,_that.latencyMs,_that.detail,_that.running);case _:
  return null;

}
}

}

/// @nodoc


class _Obd2SelfTestStep implements Obd2SelfTestStep {
  const _Obd2SelfTestStep({required this.id, this.status = Obd2SelfTestStepStatus.skipped, this.latencyMs, this.detail, this.running = false});
  

@override final  Obd2SelfTestStepId id;
@override@JsonKey() final  Obd2SelfTestStepStatus status;
@override final  int? latencyMs;
/// #3555 — the layer's captured data (raw, locale-neutral transcript
/// line: firmware id, voltage, protocol name, PID count, live values).
@override final  String? detail;
/// True while this step is the one currently executing — drives the
/// inline progress spinner. Exactly one step is `running` at a time.
@override@JsonKey() final  bool running;

/// Create a copy of Obd2SelfTestStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Obd2SelfTestStepCopyWith<_Obd2SelfTestStep> get copyWith => __$Obd2SelfTestStepCopyWithImpl<_Obd2SelfTestStep>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Obd2SelfTestStep&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.running, running) || other.running == running));
}


@override
int get hashCode => Object.hash(runtimeType,id,status,latencyMs,detail,running);

@override
String toString() {
  return 'Obd2SelfTestStep(id: $id, status: $status, latencyMs: $latencyMs, detail: $detail, running: $running)';
}


}

/// @nodoc
abstract mixin class _$Obd2SelfTestStepCopyWith<$Res> implements $Obd2SelfTestStepCopyWith<$Res> {
  factory _$Obd2SelfTestStepCopyWith(_Obd2SelfTestStep value, $Res Function(_Obd2SelfTestStep) _then) = __$Obd2SelfTestStepCopyWithImpl;
@override @useResult
$Res call({
 Obd2SelfTestStepId id, Obd2SelfTestStepStatus status, int? latencyMs, String? detail, bool running
});




}
/// @nodoc
class __$Obd2SelfTestStepCopyWithImpl<$Res>
    implements _$Obd2SelfTestStepCopyWith<$Res> {
  __$Obd2SelfTestStepCopyWithImpl(this._self, this._then);

  final _Obd2SelfTestStep _self;
  final $Res Function(_Obd2SelfTestStep) _then;

/// Create a copy of Obd2SelfTestStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? latencyMs = freezed,Object? detail = freezed,Object? running = null,}) {
  return _then(_Obd2SelfTestStep(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as Obd2SelfTestStepId,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Obd2SelfTestStepStatus,latencyMs: freezed == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int?,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$Obd2SelfTestState {

 Obd2SelfTestPhase get phase; List<Obd2SelfTestStep> get steps;/// The tri-state verdict of the completed run (#3009): passed /
/// engineOff (adapter OK, engine off) / failed. `failed` until a run
/// finishes. Drives the summary banner's colour + headline so the
/// engine-off case shows a non-alarming amber notice, not a red failure.
 Obd2SelfTestVerdict get verdict; int? get elapsedMs;
/// Create a copy of Obd2SelfTestState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Obd2SelfTestStateCopyWith<Obd2SelfTestState> get copyWith => _$Obd2SelfTestStateCopyWithImpl<Obd2SelfTestState>(this as Obd2SelfTestState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Obd2SelfTestState&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other.steps, steps)&&(identical(other.verdict, verdict) || other.verdict == verdict)&&(identical(other.elapsedMs, elapsedMs) || other.elapsedMs == elapsedMs));
}


@override
int get hashCode => Object.hash(runtimeType,phase,const DeepCollectionEquality().hash(steps),verdict,elapsedMs);

@override
String toString() {
  return 'Obd2SelfTestState(phase: $phase, steps: $steps, verdict: $verdict, elapsedMs: $elapsedMs)';
}


}

/// @nodoc
abstract mixin class $Obd2SelfTestStateCopyWith<$Res>  {
  factory $Obd2SelfTestStateCopyWith(Obd2SelfTestState value, $Res Function(Obd2SelfTestState) _then) = _$Obd2SelfTestStateCopyWithImpl;
@useResult
$Res call({
 Obd2SelfTestPhase phase, List<Obd2SelfTestStep> steps, Obd2SelfTestVerdict verdict, int? elapsedMs
});




}
/// @nodoc
class _$Obd2SelfTestStateCopyWithImpl<$Res>
    implements $Obd2SelfTestStateCopyWith<$Res> {
  _$Obd2SelfTestStateCopyWithImpl(this._self, this._then);

  final Obd2SelfTestState _self;
  final $Res Function(Obd2SelfTestState) _then;

/// Create a copy of Obd2SelfTestState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? steps = null,Object? verdict = null,Object? elapsedMs = freezed,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as Obd2SelfTestPhase,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<Obd2SelfTestStep>,verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as Obd2SelfTestVerdict,elapsedMs: freezed == elapsedMs ? _self.elapsedMs : elapsedMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Obd2SelfTestState].
extension Obd2SelfTestStatePatterns on Obd2SelfTestState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Obd2SelfTestState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Obd2SelfTestState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Obd2SelfTestState value)  $default,){
final _that = this;
switch (_that) {
case _Obd2SelfTestState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Obd2SelfTestState value)?  $default,){
final _that = this;
switch (_that) {
case _Obd2SelfTestState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Obd2SelfTestPhase phase,  List<Obd2SelfTestStep> steps,  Obd2SelfTestVerdict verdict,  int? elapsedMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Obd2SelfTestState() when $default != null:
return $default(_that.phase,_that.steps,_that.verdict,_that.elapsedMs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Obd2SelfTestPhase phase,  List<Obd2SelfTestStep> steps,  Obd2SelfTestVerdict verdict,  int? elapsedMs)  $default,) {final _that = this;
switch (_that) {
case _Obd2SelfTestState():
return $default(_that.phase,_that.steps,_that.verdict,_that.elapsedMs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Obd2SelfTestPhase phase,  List<Obd2SelfTestStep> steps,  Obd2SelfTestVerdict verdict,  int? elapsedMs)?  $default,) {final _that = this;
switch (_that) {
case _Obd2SelfTestState() when $default != null:
return $default(_that.phase,_that.steps,_that.verdict,_that.elapsedMs);case _:
  return null;

}
}

}

/// @nodoc


class _Obd2SelfTestState extends Obd2SelfTestState {
  const _Obd2SelfTestState({this.phase = Obd2SelfTestPhase.idle, final  List<Obd2SelfTestStep> steps = const <Obd2SelfTestStep>[], this.verdict = Obd2SelfTestVerdict.failed, this.elapsedMs}): _steps = steps,super._();
  

@override@JsonKey() final  Obd2SelfTestPhase phase;
 final  List<Obd2SelfTestStep> _steps;
@override@JsonKey() List<Obd2SelfTestStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

/// The tri-state verdict of the completed run (#3009): passed /
/// engineOff (adapter OK, engine off) / failed. `failed` until a run
/// finishes. Drives the summary banner's colour + headline so the
/// engine-off case shows a non-alarming amber notice, not a red failure.
@override@JsonKey() final  Obd2SelfTestVerdict verdict;
@override final  int? elapsedMs;

/// Create a copy of Obd2SelfTestState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Obd2SelfTestStateCopyWith<_Obd2SelfTestState> get copyWith => __$Obd2SelfTestStateCopyWithImpl<_Obd2SelfTestState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Obd2SelfTestState&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other._steps, _steps)&&(identical(other.verdict, verdict) || other.verdict == verdict)&&(identical(other.elapsedMs, elapsedMs) || other.elapsedMs == elapsedMs));
}


@override
int get hashCode => Object.hash(runtimeType,phase,const DeepCollectionEquality().hash(_steps),verdict,elapsedMs);

@override
String toString() {
  return 'Obd2SelfTestState(phase: $phase, steps: $steps, verdict: $verdict, elapsedMs: $elapsedMs)';
}


}

/// @nodoc
abstract mixin class _$Obd2SelfTestStateCopyWith<$Res> implements $Obd2SelfTestStateCopyWith<$Res> {
  factory _$Obd2SelfTestStateCopyWith(_Obd2SelfTestState value, $Res Function(_Obd2SelfTestState) _then) = __$Obd2SelfTestStateCopyWithImpl;
@override @useResult
$Res call({
 Obd2SelfTestPhase phase, List<Obd2SelfTestStep> steps, Obd2SelfTestVerdict verdict, int? elapsedMs
});




}
/// @nodoc
class __$Obd2SelfTestStateCopyWithImpl<$Res>
    implements _$Obd2SelfTestStateCopyWith<$Res> {
  __$Obd2SelfTestStateCopyWithImpl(this._self, this._then);

  final _Obd2SelfTestState _self;
  final $Res Function(_Obd2SelfTestState) _then;

/// Create a copy of Obd2SelfTestState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? steps = null,Object? verdict = null,Object? elapsedMs = freezed,}) {
  return _then(_Obd2SelfTestState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as Obd2SelfTestPhase,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<Obd2SelfTestStep>,verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as Obd2SelfTestVerdict,elapsedMs: freezed == elapsedMs ? _self.elapsedMs : elapsedMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
