// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'refuel_price.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RefuelPrice {

/// Numeric price in the lowest currency unit (e.g. cents).
 double get value;/// What [value] is per — liter, kWh, or whole session.
 RefuelPriceUnit get unit;/// When the upstream API last refreshed this price, if known.
 DateTime? get lastUpdated;
/// Create a copy of RefuelPrice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RefuelPriceCopyWith<RefuelPrice> get copyWith => _$RefuelPriceCopyWithImpl<RefuelPrice>(this as RefuelPrice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefuelPrice&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}


@override
int get hashCode => Object.hash(runtimeType,value,unit,lastUpdated);

@override
String toString() {
  return 'RefuelPrice(value: $value, unit: $unit, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class $RefuelPriceCopyWith<$Res>  {
  factory $RefuelPriceCopyWith(RefuelPrice value, $Res Function(RefuelPrice) _then) = _$RefuelPriceCopyWithImpl;
@useResult
$Res call({
 double value, RefuelPriceUnit unit, DateTime? lastUpdated
});




}
/// @nodoc
class _$RefuelPriceCopyWithImpl<$Res>
    implements $RefuelPriceCopyWith<$Res> {
  _$RefuelPriceCopyWithImpl(this._self, this._then);

  final RefuelPrice _self;
  final $Res Function(RefuelPrice) _then;

/// Create a copy of RefuelPrice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? unit = null,Object? lastUpdated = freezed,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as RefuelPriceUnit,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RefuelPrice].
extension RefuelPricePatterns on RefuelPrice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RefuelPrice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RefuelPrice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RefuelPrice value)  $default,){
final _that = this;
switch (_that) {
case _RefuelPrice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RefuelPrice value)?  $default,){
final _that = this;
switch (_that) {
case _RefuelPrice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double value,  RefuelPriceUnit unit,  DateTime? lastUpdated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RefuelPrice() when $default != null:
return $default(_that.value,_that.unit,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double value,  RefuelPriceUnit unit,  DateTime? lastUpdated)  $default,) {final _that = this;
switch (_that) {
case _RefuelPrice():
return $default(_that.value,_that.unit,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double value,  RefuelPriceUnit unit,  DateTime? lastUpdated)?  $default,) {final _that = this;
switch (_that) {
case _RefuelPrice() when $default != null:
return $default(_that.value,_that.unit,_that.lastUpdated);case _:
  return null;

}
}

}

/// @nodoc


class _RefuelPrice implements RefuelPrice {
  const _RefuelPrice({required this.value, required this.unit, this.lastUpdated});
  

/// Numeric price in the lowest currency unit (e.g. cents).
@override final  double value;
/// What [value] is per — liter, kWh, or whole session.
@override final  RefuelPriceUnit unit;
/// When the upstream API last refreshed this price, if known.
@override final  DateTime? lastUpdated;

/// Create a copy of RefuelPrice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RefuelPriceCopyWith<_RefuelPrice> get copyWith => __$RefuelPriceCopyWithImpl<_RefuelPrice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RefuelPrice&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}


@override
int get hashCode => Object.hash(runtimeType,value,unit,lastUpdated);

@override
String toString() {
  return 'RefuelPrice(value: $value, unit: $unit, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class _$RefuelPriceCopyWith<$Res> implements $RefuelPriceCopyWith<$Res> {
  factory _$RefuelPriceCopyWith(_RefuelPrice value, $Res Function(_RefuelPrice) _then) = __$RefuelPriceCopyWithImpl;
@override @useResult
$Res call({
 double value, RefuelPriceUnit unit, DateTime? lastUpdated
});




}
/// @nodoc
class __$RefuelPriceCopyWithImpl<$Res>
    implements _$RefuelPriceCopyWith<$Res> {
  __$RefuelPriceCopyWithImpl(this._self, this._then);

  final _RefuelPrice _self;
  final $Res Function(_RefuelPrice) _then;

/// Create a copy of RefuelPrice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? unit = null,Object? lastUpdated = freezed,}) {
  return _then(_RefuelPrice(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as RefuelPriceUnit,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
