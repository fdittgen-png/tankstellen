// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ServiceError {

 ServiceSource get source; String get message; int? get statusCode; DateTime get occurredAt;
/// Create a copy of ServiceError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceErrorCopyWith<ServiceError> get copyWith => _$ServiceErrorCopyWithImpl<ServiceError>(this as ServiceError, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceError&&(identical(other.source, source) || other.source == source)&&(identical(other.message, message) || other.message == message)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt));
}


@override
int get hashCode => Object.hash(runtimeType,source,message,statusCode,occurredAt);

@override
String toString() {
  return 'ServiceError(source: $source, message: $message, statusCode: $statusCode, occurredAt: $occurredAt)';
}


}

/// @nodoc
abstract mixin class $ServiceErrorCopyWith<$Res>  {
  factory $ServiceErrorCopyWith(ServiceError value, $Res Function(ServiceError) _then) = _$ServiceErrorCopyWithImpl;
@useResult
$Res call({
 ServiceSource source, String message, int? statusCode, DateTime occurredAt
});




}
/// @nodoc
class _$ServiceErrorCopyWithImpl<$Res>
    implements $ServiceErrorCopyWith<$Res> {
  _$ServiceErrorCopyWithImpl(this._self, this._then);

  final ServiceError _self;
  final $Res Function(ServiceError) _then;

/// Create a copy of ServiceError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? message = null,Object? statusCode = freezed,Object? occurredAt = null,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ServiceSource,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceError].
extension ServiceErrorPatterns on ServiceError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceError() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceError value)  $default,){
final _that = this;
switch (_that) {
case _ServiceError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceError value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceError() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ServiceSource source,  String message,  int? statusCode,  DateTime occurredAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceError() when $default != null:
return $default(_that.source,_that.message,_that.statusCode,_that.occurredAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ServiceSource source,  String message,  int? statusCode,  DateTime occurredAt)  $default,) {final _that = this;
switch (_that) {
case _ServiceError():
return $default(_that.source,_that.message,_that.statusCode,_that.occurredAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ServiceSource source,  String message,  int? statusCode,  DateTime occurredAt)?  $default,) {final _that = this;
switch (_that) {
case _ServiceError() when $default != null:
return $default(_that.source,_that.message,_that.statusCode,_that.occurredAt);case _:
  return null;

}
}

}

/// @nodoc


class _ServiceError implements ServiceError {
  const _ServiceError({required this.source, required this.message, this.statusCode, required this.occurredAt});
  

@override final  ServiceSource source;
@override final  String message;
@override final  int? statusCode;
@override final  DateTime occurredAt;

/// Create a copy of ServiceError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceErrorCopyWith<_ServiceError> get copyWith => __$ServiceErrorCopyWithImpl<_ServiceError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceError&&(identical(other.source, source) || other.source == source)&&(identical(other.message, message) || other.message == message)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt));
}


@override
int get hashCode => Object.hash(runtimeType,source,message,statusCode,occurredAt);

@override
String toString() {
  return 'ServiceError(source: $source, message: $message, statusCode: $statusCode, occurredAt: $occurredAt)';
}


}

/// @nodoc
abstract mixin class _$ServiceErrorCopyWith<$Res> implements $ServiceErrorCopyWith<$Res> {
  factory _$ServiceErrorCopyWith(_ServiceError value, $Res Function(_ServiceError) _then) = __$ServiceErrorCopyWithImpl;
@override @useResult
$Res call({
 ServiceSource source, String message, int? statusCode, DateTime occurredAt
});




}
/// @nodoc
class __$ServiceErrorCopyWithImpl<$Res>
    implements _$ServiceErrorCopyWith<$Res> {
  __$ServiceErrorCopyWithImpl(this._self, this._then);

  final _ServiceError _self;
  final $Res Function(_ServiceError) _then;

/// Create a copy of ServiceError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? message = null,Object? statusCode = freezed,Object? occurredAt = null,}) {
  return _then(_ServiceError(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ServiceSource,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
