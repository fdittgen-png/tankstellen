// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'open_now.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OpenNowStatus {

 OpenStatus get status; OpeningDay? get nextChangeDay; int? get nextChangeMinutes;
/// Create a copy of OpenNowStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenNowStatusCopyWith<OpenNowStatus> get copyWith => _$OpenNowStatusCopyWithImpl<OpenNowStatus>(this as OpenNowStatus, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenNowStatus&&(identical(other.status, status) || other.status == status)&&(identical(other.nextChangeDay, nextChangeDay) || other.nextChangeDay == nextChangeDay)&&(identical(other.nextChangeMinutes, nextChangeMinutes) || other.nextChangeMinutes == nextChangeMinutes));
}


@override
int get hashCode => Object.hash(runtimeType,status,nextChangeDay,nextChangeMinutes);

@override
String toString() {
  return 'OpenNowStatus(status: $status, nextChangeDay: $nextChangeDay, nextChangeMinutes: $nextChangeMinutes)';
}


}

/// @nodoc
abstract mixin class $OpenNowStatusCopyWith<$Res>  {
  factory $OpenNowStatusCopyWith(OpenNowStatus value, $Res Function(OpenNowStatus) _then) = _$OpenNowStatusCopyWithImpl;
@useResult
$Res call({
 OpenStatus status, OpeningDay? nextChangeDay, int? nextChangeMinutes
});




}
/// @nodoc
class _$OpenNowStatusCopyWithImpl<$Res>
    implements $OpenNowStatusCopyWith<$Res> {
  _$OpenNowStatusCopyWithImpl(this._self, this._then);

  final OpenNowStatus _self;
  final $Res Function(OpenNowStatus) _then;

/// Create a copy of OpenNowStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? nextChangeDay = freezed,Object? nextChangeMinutes = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OpenStatus,nextChangeDay: freezed == nextChangeDay ? _self.nextChangeDay : nextChangeDay // ignore: cast_nullable_to_non_nullable
as OpeningDay?,nextChangeMinutes: freezed == nextChangeMinutes ? _self.nextChangeMinutes : nextChangeMinutes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenNowStatus].
extension OpenNowStatusPatterns on OpenNowStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenNowStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenNowStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenNowStatus value)  $default,){
final _that = this;
switch (_that) {
case _OpenNowStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenNowStatus value)?  $default,){
final _that = this;
switch (_that) {
case _OpenNowStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OpenStatus status,  OpeningDay? nextChangeDay,  int? nextChangeMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenNowStatus() when $default != null:
return $default(_that.status,_that.nextChangeDay,_that.nextChangeMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OpenStatus status,  OpeningDay? nextChangeDay,  int? nextChangeMinutes)  $default,) {final _that = this;
switch (_that) {
case _OpenNowStatus():
return $default(_that.status,_that.nextChangeDay,_that.nextChangeMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OpenStatus status,  OpeningDay? nextChangeDay,  int? nextChangeMinutes)?  $default,) {final _that = this;
switch (_that) {
case _OpenNowStatus() when $default != null:
return $default(_that.status,_that.nextChangeDay,_that.nextChangeMinutes);case _:
  return null;

}
}

}

/// @nodoc


class _OpenNowStatus implements OpenNowStatus {
  const _OpenNowStatus({required this.status, this.nextChangeDay, this.nextChangeMinutes});
  

@override final  OpenStatus status;
@override final  OpeningDay? nextChangeDay;
@override final  int? nextChangeMinutes;

/// Create a copy of OpenNowStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenNowStatusCopyWith<_OpenNowStatus> get copyWith => __$OpenNowStatusCopyWithImpl<_OpenNowStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenNowStatus&&(identical(other.status, status) || other.status == status)&&(identical(other.nextChangeDay, nextChangeDay) || other.nextChangeDay == nextChangeDay)&&(identical(other.nextChangeMinutes, nextChangeMinutes) || other.nextChangeMinutes == nextChangeMinutes));
}


@override
int get hashCode => Object.hash(runtimeType,status,nextChangeDay,nextChangeMinutes);

@override
String toString() {
  return 'OpenNowStatus(status: $status, nextChangeDay: $nextChangeDay, nextChangeMinutes: $nextChangeMinutes)';
}


}

/// @nodoc
abstract mixin class _$OpenNowStatusCopyWith<$Res> implements $OpenNowStatusCopyWith<$Res> {
  factory _$OpenNowStatusCopyWith(_OpenNowStatus value, $Res Function(_OpenNowStatus) _then) = __$OpenNowStatusCopyWithImpl;
@override @useResult
$Res call({
 OpenStatus status, OpeningDay? nextChangeDay, int? nextChangeMinutes
});




}
/// @nodoc
class __$OpenNowStatusCopyWithImpl<$Res>
    implements _$OpenNowStatusCopyWith<$Res> {
  __$OpenNowStatusCopyWithImpl(this._self, this._then);

  final _OpenNowStatus _self;
  final $Res Function(_OpenNowStatus) _then;

/// Create a copy of OpenNowStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? nextChangeDay = freezed,Object? nextChangeMinutes = freezed,}) {
  return _then(_OpenNowStatus(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OpenStatus,nextChangeDay: freezed == nextChangeDay ? _self.nextChangeDay : nextChangeDay // ignore: cast_nullable_to_non_nullable
as OpeningDay?,nextChangeMinutes: freezed == nextChangeMinutes ? _self.nextChangeMinutes : nextChangeMinutes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
