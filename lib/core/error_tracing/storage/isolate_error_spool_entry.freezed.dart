// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'isolate_error_spool_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IsolateErrorSpoolEntry {

 DateTime get timestamp; String get isolateTaskName; String get errorMessage; String get stack; Map<String, dynamic> get contextMap;
/// Create a copy of IsolateErrorSpoolEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IsolateErrorSpoolEntryCopyWith<IsolateErrorSpoolEntry> get copyWith => _$IsolateErrorSpoolEntryCopyWithImpl<IsolateErrorSpoolEntry>(this as IsolateErrorSpoolEntry, _$identity);

  /// Serializes this IsolateErrorSpoolEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IsolateErrorSpoolEntry&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.isolateTaskName, isolateTaskName) || other.isolateTaskName == isolateTaskName)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.stack, stack) || other.stack == stack)&&const DeepCollectionEquality().equals(other.contextMap, contextMap));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,isolateTaskName,errorMessage,stack,const DeepCollectionEquality().hash(contextMap));

@override
String toString() {
  return 'IsolateErrorSpoolEntry(timestamp: $timestamp, isolateTaskName: $isolateTaskName, errorMessage: $errorMessage, stack: $stack, contextMap: $contextMap)';
}


}

/// @nodoc
abstract mixin class $IsolateErrorSpoolEntryCopyWith<$Res>  {
  factory $IsolateErrorSpoolEntryCopyWith(IsolateErrorSpoolEntry value, $Res Function(IsolateErrorSpoolEntry) _then) = _$IsolateErrorSpoolEntryCopyWithImpl;
@useResult
$Res call({
 DateTime timestamp, String isolateTaskName, String errorMessage, String stack, Map<String, dynamic> contextMap
});




}
/// @nodoc
class _$IsolateErrorSpoolEntryCopyWithImpl<$Res>
    implements $IsolateErrorSpoolEntryCopyWith<$Res> {
  _$IsolateErrorSpoolEntryCopyWithImpl(this._self, this._then);

  final IsolateErrorSpoolEntry _self;
  final $Res Function(IsolateErrorSpoolEntry) _then;

/// Create a copy of IsolateErrorSpoolEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestamp = null,Object? isolateTaskName = null,Object? errorMessage = null,Object? stack = null,Object? contextMap = null,}) {
  return _then(_self.copyWith(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,isolateTaskName: null == isolateTaskName ? _self.isolateTaskName : isolateTaskName // ignore: cast_nullable_to_non_nullable
as String,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,stack: null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as String,contextMap: null == contextMap ? _self.contextMap : contextMap // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [IsolateErrorSpoolEntry].
extension IsolateErrorSpoolEntryPatterns on IsolateErrorSpoolEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IsolateErrorSpoolEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IsolateErrorSpoolEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IsolateErrorSpoolEntry value)  $default,){
final _that = this;
switch (_that) {
case _IsolateErrorSpoolEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IsolateErrorSpoolEntry value)?  $default,){
final _that = this;
switch (_that) {
case _IsolateErrorSpoolEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime timestamp,  String isolateTaskName,  String errorMessage,  String stack,  Map<String, dynamic> contextMap)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IsolateErrorSpoolEntry() when $default != null:
return $default(_that.timestamp,_that.isolateTaskName,_that.errorMessage,_that.stack,_that.contextMap);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime timestamp,  String isolateTaskName,  String errorMessage,  String stack,  Map<String, dynamic> contextMap)  $default,) {final _that = this;
switch (_that) {
case _IsolateErrorSpoolEntry():
return $default(_that.timestamp,_that.isolateTaskName,_that.errorMessage,_that.stack,_that.contextMap);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime timestamp,  String isolateTaskName,  String errorMessage,  String stack,  Map<String, dynamic> contextMap)?  $default,) {final _that = this;
switch (_that) {
case _IsolateErrorSpoolEntry() when $default != null:
return $default(_that.timestamp,_that.isolateTaskName,_that.errorMessage,_that.stack,_that.contextMap);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IsolateErrorSpoolEntry implements IsolateErrorSpoolEntry {
  const _IsolateErrorSpoolEntry({required this.timestamp, required this.isolateTaskName, required this.errorMessage, required this.stack, final  Map<String, dynamic> contextMap = const <String, dynamic>{}}): _contextMap = contextMap;
  factory _IsolateErrorSpoolEntry.fromJson(Map<String, dynamic> json) => _$IsolateErrorSpoolEntryFromJson(json);

@override final  DateTime timestamp;
@override final  String isolateTaskName;
@override final  String errorMessage;
@override final  String stack;
 final  Map<String, dynamic> _contextMap;
@override@JsonKey() Map<String, dynamic> get contextMap {
  if (_contextMap is EqualUnmodifiableMapView) return _contextMap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_contextMap);
}


/// Create a copy of IsolateErrorSpoolEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IsolateErrorSpoolEntryCopyWith<_IsolateErrorSpoolEntry> get copyWith => __$IsolateErrorSpoolEntryCopyWithImpl<_IsolateErrorSpoolEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IsolateErrorSpoolEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IsolateErrorSpoolEntry&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.isolateTaskName, isolateTaskName) || other.isolateTaskName == isolateTaskName)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.stack, stack) || other.stack == stack)&&const DeepCollectionEquality().equals(other._contextMap, _contextMap));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,isolateTaskName,errorMessage,stack,const DeepCollectionEquality().hash(_contextMap));

@override
String toString() {
  return 'IsolateErrorSpoolEntry(timestamp: $timestamp, isolateTaskName: $isolateTaskName, errorMessage: $errorMessage, stack: $stack, contextMap: $contextMap)';
}


}

/// @nodoc
abstract mixin class _$IsolateErrorSpoolEntryCopyWith<$Res> implements $IsolateErrorSpoolEntryCopyWith<$Res> {
  factory _$IsolateErrorSpoolEntryCopyWith(_IsolateErrorSpoolEntry value, $Res Function(_IsolateErrorSpoolEntry) _then) = __$IsolateErrorSpoolEntryCopyWithImpl;
@override @useResult
$Res call({
 DateTime timestamp, String isolateTaskName, String errorMessage, String stack, Map<String, dynamic> contextMap
});




}
/// @nodoc
class __$IsolateErrorSpoolEntryCopyWithImpl<$Res>
    implements _$IsolateErrorSpoolEntryCopyWith<$Res> {
  __$IsolateErrorSpoolEntryCopyWithImpl(this._self, this._then);

  final _IsolateErrorSpoolEntry _self;
  final $Res Function(_IsolateErrorSpoolEntry) _then;

/// Create a copy of IsolateErrorSpoolEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? isolateTaskName = null,Object? errorMessage = null,Object? stack = null,Object? contextMap = null,}) {
  return _then(_IsolateErrorSpoolEntry(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,isolateTaskName: null == isolateTaskName ? _self.isolateTaskName : isolateTaskName // ignore: cast_nullable_to_non_nullable
as String,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,stack: null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as String,contextMap: null == contextMap ? _self._contextMap : contextMap // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
