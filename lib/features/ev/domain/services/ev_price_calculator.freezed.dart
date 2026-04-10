// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ev_price_calculator.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChargingCostBreakdown {

 double get totalCost; double get energyCost; double get timeCost; double get flatFee; double get parkingCost; double get blockingCost; double get kwhDelivered; String get currency;
/// Create a copy of ChargingCostBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChargingCostBreakdownCopyWith<ChargingCostBreakdown> get copyWith => _$ChargingCostBreakdownCopyWithImpl<ChargingCostBreakdown>(this as ChargingCostBreakdown, _$identity);

  /// Serializes this ChargingCostBreakdown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChargingCostBreakdown&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.energyCost, energyCost) || other.energyCost == energyCost)&&(identical(other.timeCost, timeCost) || other.timeCost == timeCost)&&(identical(other.flatFee, flatFee) || other.flatFee == flatFee)&&(identical(other.parkingCost, parkingCost) || other.parkingCost == parkingCost)&&(identical(other.blockingCost, blockingCost) || other.blockingCost == blockingCost)&&(identical(other.kwhDelivered, kwhDelivered) || other.kwhDelivered == kwhDelivered)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalCost,energyCost,timeCost,flatFee,parkingCost,blockingCost,kwhDelivered,currency);

@override
String toString() {
  return 'ChargingCostBreakdown(totalCost: $totalCost, energyCost: $energyCost, timeCost: $timeCost, flatFee: $flatFee, parkingCost: $parkingCost, blockingCost: $blockingCost, kwhDelivered: $kwhDelivered, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $ChargingCostBreakdownCopyWith<$Res>  {
  factory $ChargingCostBreakdownCopyWith(ChargingCostBreakdown value, $Res Function(ChargingCostBreakdown) _then) = _$ChargingCostBreakdownCopyWithImpl;
@useResult
$Res call({
 double totalCost, double energyCost, double timeCost, double flatFee, double parkingCost, double blockingCost, double kwhDelivered, String currency
});




}
/// @nodoc
class _$ChargingCostBreakdownCopyWithImpl<$Res>
    implements $ChargingCostBreakdownCopyWith<$Res> {
  _$ChargingCostBreakdownCopyWithImpl(this._self, this._then);

  final ChargingCostBreakdown _self;
  final $Res Function(ChargingCostBreakdown) _then;

/// Create a copy of ChargingCostBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalCost = null,Object? energyCost = null,Object? timeCost = null,Object? flatFee = null,Object? parkingCost = null,Object? blockingCost = null,Object? kwhDelivered = null,Object? currency = null,}) {
  return _then(_self.copyWith(
totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,energyCost: null == energyCost ? _self.energyCost : energyCost // ignore: cast_nullable_to_non_nullable
as double,timeCost: null == timeCost ? _self.timeCost : timeCost // ignore: cast_nullable_to_non_nullable
as double,flatFee: null == flatFee ? _self.flatFee : flatFee // ignore: cast_nullable_to_non_nullable
as double,parkingCost: null == parkingCost ? _self.parkingCost : parkingCost // ignore: cast_nullable_to_non_nullable
as double,blockingCost: null == blockingCost ? _self.blockingCost : blockingCost // ignore: cast_nullable_to_non_nullable
as double,kwhDelivered: null == kwhDelivered ? _self.kwhDelivered : kwhDelivered // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChargingCostBreakdown].
extension ChargingCostBreakdownPatterns on ChargingCostBreakdown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChargingCostBreakdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChargingCostBreakdown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChargingCostBreakdown value)  $default,){
final _that = this;
switch (_that) {
case _ChargingCostBreakdown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChargingCostBreakdown value)?  $default,){
final _that = this;
switch (_that) {
case _ChargingCostBreakdown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double totalCost,  double energyCost,  double timeCost,  double flatFee,  double parkingCost,  double blockingCost,  double kwhDelivered,  String currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChargingCostBreakdown() when $default != null:
return $default(_that.totalCost,_that.energyCost,_that.timeCost,_that.flatFee,_that.parkingCost,_that.blockingCost,_that.kwhDelivered,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double totalCost,  double energyCost,  double timeCost,  double flatFee,  double parkingCost,  double blockingCost,  double kwhDelivered,  String currency)  $default,) {final _that = this;
switch (_that) {
case _ChargingCostBreakdown():
return $default(_that.totalCost,_that.energyCost,_that.timeCost,_that.flatFee,_that.parkingCost,_that.blockingCost,_that.kwhDelivered,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double totalCost,  double energyCost,  double timeCost,  double flatFee,  double parkingCost,  double blockingCost,  double kwhDelivered,  String currency)?  $default,) {final _that = this;
switch (_that) {
case _ChargingCostBreakdown() when $default != null:
return $default(_that.totalCost,_that.energyCost,_that.timeCost,_that.flatFee,_that.parkingCost,_that.blockingCost,_that.kwhDelivered,_that.currency);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChargingCostBreakdown extends ChargingCostBreakdown {
  const _ChargingCostBreakdown({required this.totalCost, this.energyCost = 0, this.timeCost = 0, this.flatFee = 0, this.parkingCost = 0, this.blockingCost = 0, this.kwhDelivered = 0, this.currency = 'EUR'}): super._();
  factory _ChargingCostBreakdown.fromJson(Map<String, dynamic> json) => _$ChargingCostBreakdownFromJson(json);

@override final  double totalCost;
@override@JsonKey() final  double energyCost;
@override@JsonKey() final  double timeCost;
@override@JsonKey() final  double flatFee;
@override@JsonKey() final  double parkingCost;
@override@JsonKey() final  double blockingCost;
@override@JsonKey() final  double kwhDelivered;
@override@JsonKey() final  String currency;

/// Create a copy of ChargingCostBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChargingCostBreakdownCopyWith<_ChargingCostBreakdown> get copyWith => __$ChargingCostBreakdownCopyWithImpl<_ChargingCostBreakdown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChargingCostBreakdownToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChargingCostBreakdown&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.energyCost, energyCost) || other.energyCost == energyCost)&&(identical(other.timeCost, timeCost) || other.timeCost == timeCost)&&(identical(other.flatFee, flatFee) || other.flatFee == flatFee)&&(identical(other.parkingCost, parkingCost) || other.parkingCost == parkingCost)&&(identical(other.blockingCost, blockingCost) || other.blockingCost == blockingCost)&&(identical(other.kwhDelivered, kwhDelivered) || other.kwhDelivered == kwhDelivered)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalCost,energyCost,timeCost,flatFee,parkingCost,blockingCost,kwhDelivered,currency);

@override
String toString() {
  return 'ChargingCostBreakdown(totalCost: $totalCost, energyCost: $energyCost, timeCost: $timeCost, flatFee: $flatFee, parkingCost: $parkingCost, blockingCost: $blockingCost, kwhDelivered: $kwhDelivered, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$ChargingCostBreakdownCopyWith<$Res> implements $ChargingCostBreakdownCopyWith<$Res> {
  factory _$ChargingCostBreakdownCopyWith(_ChargingCostBreakdown value, $Res Function(_ChargingCostBreakdown) _then) = __$ChargingCostBreakdownCopyWithImpl;
@override @useResult
$Res call({
 double totalCost, double energyCost, double timeCost, double flatFee, double parkingCost, double blockingCost, double kwhDelivered, String currency
});




}
/// @nodoc
class __$ChargingCostBreakdownCopyWithImpl<$Res>
    implements _$ChargingCostBreakdownCopyWith<$Res> {
  __$ChargingCostBreakdownCopyWithImpl(this._self, this._then);

  final _ChargingCostBreakdown _self;
  final $Res Function(_ChargingCostBreakdown) _then;

/// Create a copy of ChargingCostBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalCost = null,Object? energyCost = null,Object? timeCost = null,Object? flatFee = null,Object? parkingCost = null,Object? blockingCost = null,Object? kwhDelivered = null,Object? currency = null,}) {
  return _then(_ChargingCostBreakdown(
totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,energyCost: null == energyCost ? _self.energyCost : energyCost // ignore: cast_nullable_to_non_nullable
as double,timeCost: null == timeCost ? _self.timeCost : timeCost // ignore: cast_nullable_to_non_nullable
as double,flatFee: null == flatFee ? _self.flatFee : flatFee // ignore: cast_nullable_to_non_nullable
as double,parkingCost: null == parkingCost ? _self.parkingCost : parkingCost // ignore: cast_nullable_to_non_nullable
as double,blockingCost: null == blockingCost ? _self.blockingCost : blockingCost // ignore: cast_nullable_to_non_nullable
as double,kwhDelivered: null == kwhDelivered ? _self.kwhDelivered : kwhDelivered // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TariffComparisonEntry {

 String get tariffId; double get totalCost; String get currency;
/// Create a copy of TariffComparisonEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TariffComparisonEntryCopyWith<TariffComparisonEntry> get copyWith => _$TariffComparisonEntryCopyWithImpl<TariffComparisonEntry>(this as TariffComparisonEntry, _$identity);

  /// Serializes this TariffComparisonEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TariffComparisonEntry&&(identical(other.tariffId, tariffId) || other.tariffId == tariffId)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tariffId,totalCost,currency);

@override
String toString() {
  return 'TariffComparisonEntry(tariffId: $tariffId, totalCost: $totalCost, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $TariffComparisonEntryCopyWith<$Res>  {
  factory $TariffComparisonEntryCopyWith(TariffComparisonEntry value, $Res Function(TariffComparisonEntry) _then) = _$TariffComparisonEntryCopyWithImpl;
@useResult
$Res call({
 String tariffId, double totalCost, String currency
});




}
/// @nodoc
class _$TariffComparisonEntryCopyWithImpl<$Res>
    implements $TariffComparisonEntryCopyWith<$Res> {
  _$TariffComparisonEntryCopyWithImpl(this._self, this._then);

  final TariffComparisonEntry _self;
  final $Res Function(TariffComparisonEntry) _then;

/// Create a copy of TariffComparisonEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tariffId = null,Object? totalCost = null,Object? currency = null,}) {
  return _then(_self.copyWith(
tariffId: null == tariffId ? _self.tariffId : tariffId // ignore: cast_nullable_to_non_nullable
as String,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TariffComparisonEntry].
extension TariffComparisonEntryPatterns on TariffComparisonEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TariffComparisonEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TariffComparisonEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TariffComparisonEntry value)  $default,){
final _that = this;
switch (_that) {
case _TariffComparisonEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TariffComparisonEntry value)?  $default,){
final _that = this;
switch (_that) {
case _TariffComparisonEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tariffId,  double totalCost,  String currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TariffComparisonEntry() when $default != null:
return $default(_that.tariffId,_that.totalCost,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tariffId,  double totalCost,  String currency)  $default,) {final _that = this;
switch (_that) {
case _TariffComparisonEntry():
return $default(_that.tariffId,_that.totalCost,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tariffId,  double totalCost,  String currency)?  $default,) {final _that = this;
switch (_that) {
case _TariffComparisonEntry() when $default != null:
return $default(_that.tariffId,_that.totalCost,_that.currency);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TariffComparisonEntry implements TariffComparisonEntry {
  const _TariffComparisonEntry({required this.tariffId, required this.totalCost, required this.currency});
  factory _TariffComparisonEntry.fromJson(Map<String, dynamic> json) => _$TariffComparisonEntryFromJson(json);

@override final  String tariffId;
@override final  double totalCost;
@override final  String currency;

/// Create a copy of TariffComparisonEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TariffComparisonEntryCopyWith<_TariffComparisonEntry> get copyWith => __$TariffComparisonEntryCopyWithImpl<_TariffComparisonEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TariffComparisonEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TariffComparisonEntry&&(identical(other.tariffId, tariffId) || other.tariffId == tariffId)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tariffId,totalCost,currency);

@override
String toString() {
  return 'TariffComparisonEntry(tariffId: $tariffId, totalCost: $totalCost, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$TariffComparisonEntryCopyWith<$Res> implements $TariffComparisonEntryCopyWith<$Res> {
  factory _$TariffComparisonEntryCopyWith(_TariffComparisonEntry value, $Res Function(_TariffComparisonEntry) _then) = __$TariffComparisonEntryCopyWithImpl;
@override @useResult
$Res call({
 String tariffId, double totalCost, String currency
});




}
/// @nodoc
class __$TariffComparisonEntryCopyWithImpl<$Res>
    implements _$TariffComparisonEntryCopyWith<$Res> {
  __$TariffComparisonEntryCopyWithImpl(this._self, this._then);

  final _TariffComparisonEntry _self;
  final $Res Function(_TariffComparisonEntry) _then;

/// Create a copy of TariffComparisonEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tariffId = null,Object? totalCost = null,Object? currency = null,}) {
  return _then(_TariffComparisonEntry(
tariffId: null == tariffId ? _self.tariffId : tariffId // ignore: cast_nullable_to_non_nullable
as String,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
