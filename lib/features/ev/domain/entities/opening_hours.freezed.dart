// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'opening_hours.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RegularHours {

 int get weekday; String get periodBegin; String get periodEnd;
/// Create a copy of RegularHours
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegularHoursCopyWith<RegularHours> get copyWith => _$RegularHoursCopyWithImpl<RegularHours>(this as RegularHours, _$identity);

  /// Serializes this RegularHours to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegularHours&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.periodBegin, periodBegin) || other.periodBegin == periodBegin)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekday,periodBegin,periodEnd);

@override
String toString() {
  return 'RegularHours(weekday: $weekday, periodBegin: $periodBegin, periodEnd: $periodEnd)';
}


}

/// @nodoc
abstract mixin class $RegularHoursCopyWith<$Res>  {
  factory $RegularHoursCopyWith(RegularHours value, $Res Function(RegularHours) _then) = _$RegularHoursCopyWithImpl;
@useResult
$Res call({
 int weekday, String periodBegin, String periodEnd
});




}
/// @nodoc
class _$RegularHoursCopyWithImpl<$Res>
    implements $RegularHoursCopyWith<$Res> {
  _$RegularHoursCopyWithImpl(this._self, this._then);

  final RegularHours _self;
  final $Res Function(RegularHours) _then;

/// Create a copy of RegularHours
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekday = null,Object? periodBegin = null,Object? periodEnd = null,}) {
  return _then(_self.copyWith(
weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,periodBegin: null == periodBegin ? _self.periodBegin : periodBegin // ignore: cast_nullable_to_non_nullable
as String,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RegularHours].
extension RegularHoursPatterns on RegularHours {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegularHours value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegularHours() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegularHours value)  $default,){
final _that = this;
switch (_that) {
case _RegularHours():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegularHours value)?  $default,){
final _that = this;
switch (_that) {
case _RegularHours() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int weekday,  String periodBegin,  String periodEnd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegularHours() when $default != null:
return $default(_that.weekday,_that.periodBegin,_that.periodEnd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int weekday,  String periodBegin,  String periodEnd)  $default,) {final _that = this;
switch (_that) {
case _RegularHours():
return $default(_that.weekday,_that.periodBegin,_that.periodEnd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int weekday,  String periodBegin,  String periodEnd)?  $default,) {final _that = this;
switch (_that) {
case _RegularHours() when $default != null:
return $default(_that.weekday,_that.periodBegin,_that.periodEnd);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RegularHours implements RegularHours {
  const _RegularHours({required this.weekday, required this.periodBegin, required this.periodEnd});
  factory _RegularHours.fromJson(Map<String, dynamic> json) => _$RegularHoursFromJson(json);

@override final  int weekday;
@override final  String periodBegin;
@override final  String periodEnd;

/// Create a copy of RegularHours
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegularHoursCopyWith<_RegularHours> get copyWith => __$RegularHoursCopyWithImpl<_RegularHours>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegularHoursToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegularHours&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.periodBegin, periodBegin) || other.periodBegin == periodBegin)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekday,periodBegin,periodEnd);

@override
String toString() {
  return 'RegularHours(weekday: $weekday, periodBegin: $periodBegin, periodEnd: $periodEnd)';
}


}

/// @nodoc
abstract mixin class _$RegularHoursCopyWith<$Res> implements $RegularHoursCopyWith<$Res> {
  factory _$RegularHoursCopyWith(_RegularHours value, $Res Function(_RegularHours) _then) = __$RegularHoursCopyWithImpl;
@override @useResult
$Res call({
 int weekday, String periodBegin, String periodEnd
});




}
/// @nodoc
class __$RegularHoursCopyWithImpl<$Res>
    implements _$RegularHoursCopyWith<$Res> {
  __$RegularHoursCopyWithImpl(this._self, this._then);

  final _RegularHours _self;
  final $Res Function(_RegularHours) _then;

/// Create a copy of RegularHours
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekday = null,Object? periodBegin = null,Object? periodEnd = null,}) {
  return _then(_RegularHours(
weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,periodBegin: null == periodBegin ? _self.periodBegin : periodBegin // ignore: cast_nullable_to_non_nullable
as String,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$OpeningHours {

 bool get twentyFourSeven;@RegularHoursListConverter() List<RegularHours> get regularHours;
/// Create a copy of OpeningHours
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpeningHoursCopyWith<OpeningHours> get copyWith => _$OpeningHoursCopyWithImpl<OpeningHours>(this as OpeningHours, _$identity);

  /// Serializes this OpeningHours to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpeningHours&&(identical(other.twentyFourSeven, twentyFourSeven) || other.twentyFourSeven == twentyFourSeven)&&const DeepCollectionEquality().equals(other.regularHours, regularHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,twentyFourSeven,const DeepCollectionEquality().hash(regularHours));

@override
String toString() {
  return 'OpeningHours(twentyFourSeven: $twentyFourSeven, regularHours: $regularHours)';
}


}

/// @nodoc
abstract mixin class $OpeningHoursCopyWith<$Res>  {
  factory $OpeningHoursCopyWith(OpeningHours value, $Res Function(OpeningHours) _then) = _$OpeningHoursCopyWithImpl;
@useResult
$Res call({
 bool twentyFourSeven,@RegularHoursListConverter() List<RegularHours> regularHours
});




}
/// @nodoc
class _$OpeningHoursCopyWithImpl<$Res>
    implements $OpeningHoursCopyWith<$Res> {
  _$OpeningHoursCopyWithImpl(this._self, this._then);

  final OpeningHours _self;
  final $Res Function(OpeningHours) _then;

/// Create a copy of OpeningHours
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? twentyFourSeven = null,Object? regularHours = null,}) {
  return _then(_self.copyWith(
twentyFourSeven: null == twentyFourSeven ? _self.twentyFourSeven : twentyFourSeven // ignore: cast_nullable_to_non_nullable
as bool,regularHours: null == regularHours ? _self.regularHours : regularHours // ignore: cast_nullable_to_non_nullable
as List<RegularHours>,
  ));
}

}


/// Adds pattern-matching-related methods to [OpeningHours].
extension OpeningHoursPatterns on OpeningHours {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpeningHours value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpeningHours() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpeningHours value)  $default,){
final _that = this;
switch (_that) {
case _OpeningHours():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpeningHours value)?  $default,){
final _that = this;
switch (_that) {
case _OpeningHours() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool twentyFourSeven, @RegularHoursListConverter()  List<RegularHours> regularHours)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpeningHours() when $default != null:
return $default(_that.twentyFourSeven,_that.regularHours);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool twentyFourSeven, @RegularHoursListConverter()  List<RegularHours> regularHours)  $default,) {final _that = this;
switch (_that) {
case _OpeningHours():
return $default(_that.twentyFourSeven,_that.regularHours);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool twentyFourSeven, @RegularHoursListConverter()  List<RegularHours> regularHours)?  $default,) {final _that = this;
switch (_that) {
case _OpeningHours() when $default != null:
return $default(_that.twentyFourSeven,_that.regularHours);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpeningHours implements OpeningHours {
  const _OpeningHours({this.twentyFourSeven = false, @RegularHoursListConverter() final  List<RegularHours> regularHours = const <RegularHours>[]}): _regularHours = regularHours;
  factory _OpeningHours.fromJson(Map<String, dynamic> json) => _$OpeningHoursFromJson(json);

@override@JsonKey() final  bool twentyFourSeven;
 final  List<RegularHours> _regularHours;
@override@JsonKey()@RegularHoursListConverter() List<RegularHours> get regularHours {
  if (_regularHours is EqualUnmodifiableListView) return _regularHours;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_regularHours);
}


/// Create a copy of OpeningHours
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpeningHoursCopyWith<_OpeningHours> get copyWith => __$OpeningHoursCopyWithImpl<_OpeningHours>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpeningHoursToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpeningHours&&(identical(other.twentyFourSeven, twentyFourSeven) || other.twentyFourSeven == twentyFourSeven)&&const DeepCollectionEquality().equals(other._regularHours, _regularHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,twentyFourSeven,const DeepCollectionEquality().hash(_regularHours));

@override
String toString() {
  return 'OpeningHours(twentyFourSeven: $twentyFourSeven, regularHours: $regularHours)';
}


}

/// @nodoc
abstract mixin class _$OpeningHoursCopyWith<$Res> implements $OpeningHoursCopyWith<$Res> {
  factory _$OpeningHoursCopyWith(_OpeningHours value, $Res Function(_OpeningHours) _then) = __$OpeningHoursCopyWithImpl;
@override @useResult
$Res call({
 bool twentyFourSeven,@RegularHoursListConverter() List<RegularHours> regularHours
});




}
/// @nodoc
class __$OpeningHoursCopyWithImpl<$Res>
    implements _$OpeningHoursCopyWith<$Res> {
  __$OpeningHoursCopyWithImpl(this._self, this._then);

  final _OpeningHours _self;
  final $Res Function(_OpeningHours) _then;

/// Create a copy of OpeningHours
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? twentyFourSeven = null,Object? regularHours = null,}) {
  return _then(_OpeningHours(
twentyFourSeven: null == twentyFourSeven ? _self.twentyFourSeven : twentyFourSeven // ignore: cast_nullable_to_non_nullable
as bool,regularHours: null == regularHours ? _self._regularHours : regularHours // ignore: cast_nullable_to_non_nullable
as List<RegularHours>,
  ));
}


}

// dart format on
