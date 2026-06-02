// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'radar_swipe_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RadarSwipeState {

/// Index into the distance-ranked candidate list. 0 = the nearest
/// station. The card clamps this against the live list length on every
/// build, so a stale index from a shrunk list never points past the end.
 int get currentIndex;
/// Create a copy of RadarSwipeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadarSwipeStateCopyWith<RadarSwipeState> get copyWith => _$RadarSwipeStateCopyWithImpl<RadarSwipeState>(this as RadarSwipeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadarSwipeState&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex));
}


@override
int get hashCode => Object.hash(runtimeType,currentIndex);

@override
String toString() {
  return 'RadarSwipeState(currentIndex: $currentIndex)';
}


}

/// @nodoc
abstract mixin class $RadarSwipeStateCopyWith<$Res>  {
  factory $RadarSwipeStateCopyWith(RadarSwipeState value, $Res Function(RadarSwipeState) _then) = _$RadarSwipeStateCopyWithImpl;
@useResult
$Res call({
 int currentIndex
});




}
/// @nodoc
class _$RadarSwipeStateCopyWithImpl<$Res>
    implements $RadarSwipeStateCopyWith<$Res> {
  _$RadarSwipeStateCopyWithImpl(this._self, this._then);

  final RadarSwipeState _self;
  final $Res Function(RadarSwipeState) _then;

/// Create a copy of RadarSwipeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentIndex = null,}) {
  return _then(_self.copyWith(
currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RadarSwipeState].
extension RadarSwipeStatePatterns on RadarSwipeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadarSwipeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadarSwipeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadarSwipeState value)  $default,){
final _that = this;
switch (_that) {
case _RadarSwipeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadarSwipeState value)?  $default,){
final _that = this;
switch (_that) {
case _RadarSwipeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadarSwipeState() when $default != null:
return $default(_that.currentIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentIndex)  $default,) {final _that = this;
switch (_that) {
case _RadarSwipeState():
return $default(_that.currentIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentIndex)?  $default,) {final _that = this;
switch (_that) {
case _RadarSwipeState() when $default != null:
return $default(_that.currentIndex);case _:
  return null;

}
}

}

/// @nodoc


class _RadarSwipeState implements RadarSwipeState {
  const _RadarSwipeState({this.currentIndex = 0});
  

/// Index into the distance-ranked candidate list. 0 = the nearest
/// station. The card clamps this against the live list length on every
/// build, so a stale index from a shrunk list never points past the end.
@override@JsonKey() final  int currentIndex;

/// Create a copy of RadarSwipeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadarSwipeStateCopyWith<_RadarSwipeState> get copyWith => __$RadarSwipeStateCopyWithImpl<_RadarSwipeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadarSwipeState&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex));
}


@override
int get hashCode => Object.hash(runtimeType,currentIndex);

@override
String toString() {
  return 'RadarSwipeState(currentIndex: $currentIndex)';
}


}

/// @nodoc
abstract mixin class _$RadarSwipeStateCopyWith<$Res> implements $RadarSwipeStateCopyWith<$Res> {
  factory _$RadarSwipeStateCopyWith(_RadarSwipeState value, $Res Function(_RadarSwipeState) _then) = __$RadarSwipeStateCopyWithImpl;
@override @useResult
$Res call({
 int currentIndex
});




}
/// @nodoc
class __$RadarSwipeStateCopyWithImpl<$Res>
    implements _$RadarSwipeStateCopyWith<$Res> {
  __$RadarSwipeStateCopyWithImpl(this._self, this._then);

  final _RadarSwipeState _self;
  final $Res Function(_RadarSwipeState) _then;

/// Create a copy of RadarSwipeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentIndex = null,}) {
  return _then(_RadarSwipeState(
currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
