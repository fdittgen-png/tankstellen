// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'loyalty_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LoyaltyCard {

/// Stable id, generated client-side. UUID-ish strings are fine —
/// the field is opaque to the storage layer.
 String get id;/// The fuel-club brand this card belongs to. Matched against a
/// station's canonical brand at price-display time.
 LoyaltyBrand get brand;/// Per-litre discount in the active country's currency, applied
/// when the user fills up at a [brand] station. Stored as a
/// positive number; the price-display layer subtracts it.
/// Validated `> 0` at create time; defensive code in the price
/// formatter still guards against negative values surviving a
/// hand-edited Hive dump.
 double get discountPerLiter;/// Free-form short label the user attaches to the card so they
/// can tell two cards of the same brand apart (e.g. "Personal"
/// vs. "Company"). Optional — defaults to the brand's
/// `canonicalBrand` when blank.
 String get label;/// When the card was added. Used purely for display ordering on
/// the settings sub-screen (newest-first).
 DateTime get addedAt;/// User toggle that hides this card from the active discount map
/// without deleting it. Disabled cards never apply a discount and
/// never produce a badge on the station card.
 bool get enabled;
/// Create a copy of LoyaltyCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoyaltyCardCopyWith<LoyaltyCard> get copyWith => _$LoyaltyCardCopyWithImpl<LoyaltyCard>(this as LoyaltyCard, _$identity);

  /// Serializes this LoyaltyCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoyaltyCard&&(identical(other.id, id) || other.id == id)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.discountPerLiter, discountPerLiter) || other.discountPerLiter == discountPerLiter)&&(identical(other.label, label) || other.label == label)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,brand,discountPerLiter,label,addedAt,enabled);

@override
String toString() {
  return 'LoyaltyCard(id: $id, brand: $brand, discountPerLiter: $discountPerLiter, label: $label, addedAt: $addedAt, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $LoyaltyCardCopyWith<$Res>  {
  factory $LoyaltyCardCopyWith(LoyaltyCard value, $Res Function(LoyaltyCard) _then) = _$LoyaltyCardCopyWithImpl;
@useResult
$Res call({
 String id, LoyaltyBrand brand, double discountPerLiter, String label, DateTime addedAt, bool enabled
});




}
/// @nodoc
class _$LoyaltyCardCopyWithImpl<$Res>
    implements $LoyaltyCardCopyWith<$Res> {
  _$LoyaltyCardCopyWithImpl(this._self, this._then);

  final LoyaltyCard _self;
  final $Res Function(LoyaltyCard) _then;

/// Create a copy of LoyaltyCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? brand = null,Object? discountPerLiter = null,Object? label = null,Object? addedAt = null,Object? enabled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as LoyaltyBrand,discountPerLiter: null == discountPerLiter ? _self.discountPerLiter : discountPerLiter // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LoyaltyCard].
extension LoyaltyCardPatterns on LoyaltyCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LoyaltyCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoyaltyCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LoyaltyCard value)  $default,){
final _that = this;
switch (_that) {
case _LoyaltyCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LoyaltyCard value)?  $default,){
final _that = this;
switch (_that) {
case _LoyaltyCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  LoyaltyBrand brand,  double discountPerLiter,  String label,  DateTime addedAt,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoyaltyCard() when $default != null:
return $default(_that.id,_that.brand,_that.discountPerLiter,_that.label,_that.addedAt,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  LoyaltyBrand brand,  double discountPerLiter,  String label,  DateTime addedAt,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _LoyaltyCard():
return $default(_that.id,_that.brand,_that.discountPerLiter,_that.label,_that.addedAt,_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  LoyaltyBrand brand,  double discountPerLiter,  String label,  DateTime addedAt,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _LoyaltyCard() when $default != null:
return $default(_that.id,_that.brand,_that.discountPerLiter,_that.label,_that.addedAt,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LoyaltyCard implements LoyaltyCard {
  const _LoyaltyCard({required this.id, required this.brand, required this.discountPerLiter, required this.label, required this.addedAt, this.enabled = true});
  factory _LoyaltyCard.fromJson(Map<String, dynamic> json) => _$LoyaltyCardFromJson(json);

/// Stable id, generated client-side. UUID-ish strings are fine —
/// the field is opaque to the storage layer.
@override final  String id;
/// The fuel-club brand this card belongs to. Matched against a
/// station's canonical brand at price-display time.
@override final  LoyaltyBrand brand;
/// Per-litre discount in the active country's currency, applied
/// when the user fills up at a [brand] station. Stored as a
/// positive number; the price-display layer subtracts it.
/// Validated `> 0` at create time; defensive code in the price
/// formatter still guards against negative values surviving a
/// hand-edited Hive dump.
@override final  double discountPerLiter;
/// Free-form short label the user attaches to the card so they
/// can tell two cards of the same brand apart (e.g. "Personal"
/// vs. "Company"). Optional — defaults to the brand's
/// `canonicalBrand` when blank.
@override final  String label;
/// When the card was added. Used purely for display ordering on
/// the settings sub-screen (newest-first).
@override final  DateTime addedAt;
/// User toggle that hides this card from the active discount map
/// without deleting it. Disabled cards never apply a discount and
/// never produce a badge on the station card.
@override@JsonKey() final  bool enabled;

/// Create a copy of LoyaltyCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoyaltyCardCopyWith<_LoyaltyCard> get copyWith => __$LoyaltyCardCopyWithImpl<_LoyaltyCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LoyaltyCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoyaltyCard&&(identical(other.id, id) || other.id == id)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.discountPerLiter, discountPerLiter) || other.discountPerLiter == discountPerLiter)&&(identical(other.label, label) || other.label == label)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,brand,discountPerLiter,label,addedAt,enabled);

@override
String toString() {
  return 'LoyaltyCard(id: $id, brand: $brand, discountPerLiter: $discountPerLiter, label: $label, addedAt: $addedAt, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$LoyaltyCardCopyWith<$Res> implements $LoyaltyCardCopyWith<$Res> {
  factory _$LoyaltyCardCopyWith(_LoyaltyCard value, $Res Function(_LoyaltyCard) _then) = __$LoyaltyCardCopyWithImpl;
@override @useResult
$Res call({
 String id, LoyaltyBrand brand, double discountPerLiter, String label, DateTime addedAt, bool enabled
});




}
/// @nodoc
class __$LoyaltyCardCopyWithImpl<$Res>
    implements _$LoyaltyCardCopyWith<$Res> {
  __$LoyaltyCardCopyWithImpl(this._self, this._then);

  final _LoyaltyCard _self;
  final $Res Function(_LoyaltyCard) _then;

/// Create a copy of LoyaltyCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? brand = null,Object? discountPerLiter = null,Object? label = null,Object? addedAt = null,Object? enabled = null,}) {
  return _then(_LoyaltyCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as LoyaltyBrand,discountPerLiter: null == discountPerLiter ? _self.discountPerLiter : discountPerLiter // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
