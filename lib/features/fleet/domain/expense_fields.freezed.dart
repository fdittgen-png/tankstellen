// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense_fields.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExtractedReceiptFields {

/// Station / retailer name as printed.
 String? get stationName;/// When the purchase happened, per the document.
 DateTime? get occurredAt;/// `FuelType.apiValue` of the grade, when one was recognised.
 String? get fuelApiValue;/// Volume dispensed, in litres.
 double? get litres;/// Unit price per litre in the major unit of [total]'s currency.
 double? get pricePerLitre;/// Total charged.
 Money? get total;/// VAT amount as printed — a separate field from [total] and from
/// any reimbursement figure. ADR 0025: three fields, never one.
 Money? get vat;/// VAT rate in percent as printed (`20.0`).
 double? get vatRate;/// Masked payment / fuel-card reference. Never a full card number —
/// the masking happens in the extractor, not here.
 String? get paymentReference;/// Odometer in kilometres, when the forecourt printed one.
 double? get odometerKm;
/// Create a copy of ExtractedReceiptFields
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExtractedReceiptFieldsCopyWith<ExtractedReceiptFields> get copyWith => _$ExtractedReceiptFieldsCopyWithImpl<ExtractedReceiptFields>(this as ExtractedReceiptFields, _$identity);

  /// Serializes this ExtractedReceiptFields to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExtractedReceiptFields&&(identical(other.stationName, stationName) || other.stationName == stationName)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.fuelApiValue, fuelApiValue) || other.fuelApiValue == fuelApiValue)&&(identical(other.litres, litres) || other.litres == litres)&&(identical(other.pricePerLitre, pricePerLitre) || other.pricePerLitre == pricePerLitre)&&(identical(other.total, total) || other.total == total)&&(identical(other.vat, vat) || other.vat == vat)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.paymentReference, paymentReference) || other.paymentReference == paymentReference)&&(identical(other.odometerKm, odometerKm) || other.odometerKm == odometerKm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stationName,occurredAt,fuelApiValue,litres,pricePerLitre,total,vat,vatRate,paymentReference,odometerKm);

@override
String toString() {
  return 'ExtractedReceiptFields(stationName: $stationName, occurredAt: $occurredAt, fuelApiValue: $fuelApiValue, litres: $litres, pricePerLitre: $pricePerLitre, total: $total, vat: $vat, vatRate: $vatRate, paymentReference: $paymentReference, odometerKm: $odometerKm)';
}


}

/// @nodoc
abstract mixin class $ExtractedReceiptFieldsCopyWith<$Res>  {
  factory $ExtractedReceiptFieldsCopyWith(ExtractedReceiptFields value, $Res Function(ExtractedReceiptFields) _then) = _$ExtractedReceiptFieldsCopyWithImpl;
@useResult
$Res call({
 String? stationName, DateTime? occurredAt, String? fuelApiValue, double? litres, double? pricePerLitre, Money? total, Money? vat, double? vatRate, String? paymentReference, double? odometerKm
});




}
/// @nodoc
class _$ExtractedReceiptFieldsCopyWithImpl<$Res>
    implements $ExtractedReceiptFieldsCopyWith<$Res> {
  _$ExtractedReceiptFieldsCopyWithImpl(this._self, this._then);

  final ExtractedReceiptFields _self;
  final $Res Function(ExtractedReceiptFields) _then;

/// Create a copy of ExtractedReceiptFields
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stationName = freezed,Object? occurredAt = freezed,Object? fuelApiValue = freezed,Object? litres = freezed,Object? pricePerLitre = freezed,Object? total = freezed,Object? vat = freezed,Object? vatRate = freezed,Object? paymentReference = freezed,Object? odometerKm = freezed,}) {
  return _then(_self.copyWith(
stationName: freezed == stationName ? _self.stationName : stationName // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,fuelApiValue: freezed == fuelApiValue ? _self.fuelApiValue : fuelApiValue // ignore: cast_nullable_to_non_nullable
as String?,litres: freezed == litres ? _self.litres : litres // ignore: cast_nullable_to_non_nullable
as double?,pricePerLitre: freezed == pricePerLitre ? _self.pricePerLitre : pricePerLitre // ignore: cast_nullable_to_non_nullable
as double?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Money?,vat: freezed == vat ? _self.vat : vat // ignore: cast_nullable_to_non_nullable
as Money?,vatRate: freezed == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as double?,paymentReference: freezed == paymentReference ? _self.paymentReference : paymentReference // ignore: cast_nullable_to_non_nullable
as String?,odometerKm: freezed == odometerKm ? _self.odometerKm : odometerKm // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExtractedReceiptFields].
extension ExtractedReceiptFieldsPatterns on ExtractedReceiptFields {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExtractedReceiptFields value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExtractedReceiptFields() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExtractedReceiptFields value)  $default,){
final _that = this;
switch (_that) {
case _ExtractedReceiptFields():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExtractedReceiptFields value)?  $default,){
final _that = this;
switch (_that) {
case _ExtractedReceiptFields() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? stationName,  DateTime? occurredAt,  String? fuelApiValue,  double? litres,  double? pricePerLitre,  Money? total,  Money? vat,  double? vatRate,  String? paymentReference,  double? odometerKm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExtractedReceiptFields() when $default != null:
return $default(_that.stationName,_that.occurredAt,_that.fuelApiValue,_that.litres,_that.pricePerLitre,_that.total,_that.vat,_that.vatRate,_that.paymentReference,_that.odometerKm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? stationName,  DateTime? occurredAt,  String? fuelApiValue,  double? litres,  double? pricePerLitre,  Money? total,  Money? vat,  double? vatRate,  String? paymentReference,  double? odometerKm)  $default,) {final _that = this;
switch (_that) {
case _ExtractedReceiptFields():
return $default(_that.stationName,_that.occurredAt,_that.fuelApiValue,_that.litres,_that.pricePerLitre,_that.total,_that.vat,_that.vatRate,_that.paymentReference,_that.odometerKm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? stationName,  DateTime? occurredAt,  String? fuelApiValue,  double? litres,  double? pricePerLitre,  Money? total,  Money? vat,  double? vatRate,  String? paymentReference,  double? odometerKm)?  $default,) {final _that = this;
switch (_that) {
case _ExtractedReceiptFields() when $default != null:
return $default(_that.stationName,_that.occurredAt,_that.fuelApiValue,_that.litres,_that.pricePerLitre,_that.total,_that.vat,_that.vatRate,_that.paymentReference,_that.odometerKm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExtractedReceiptFields implements ExtractedReceiptFields {
  const _ExtractedReceiptFields({this.stationName, this.occurredAt, this.fuelApiValue, this.litres, this.pricePerLitre, this.total, this.vat, this.vatRate, this.paymentReference, this.odometerKm});
  factory _ExtractedReceiptFields.fromJson(Map<String, dynamic> json) => _$ExtractedReceiptFieldsFromJson(json);

/// Station / retailer name as printed.
@override final  String? stationName;
/// When the purchase happened, per the document.
@override final  DateTime? occurredAt;
/// `FuelType.apiValue` of the grade, when one was recognised.
@override final  String? fuelApiValue;
/// Volume dispensed, in litres.
@override final  double? litres;
/// Unit price per litre in the major unit of [total]'s currency.
@override final  double? pricePerLitre;
/// Total charged.
@override final  Money? total;
/// VAT amount as printed — a separate field from [total] and from
/// any reimbursement figure. ADR 0025: three fields, never one.
@override final  Money? vat;
/// VAT rate in percent as printed (`20.0`).
@override final  double? vatRate;
/// Masked payment / fuel-card reference. Never a full card number —
/// the masking happens in the extractor, not here.
@override final  String? paymentReference;
/// Odometer in kilometres, when the forecourt printed one.
@override final  double? odometerKm;

/// Create a copy of ExtractedReceiptFields
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExtractedReceiptFieldsCopyWith<_ExtractedReceiptFields> get copyWith => __$ExtractedReceiptFieldsCopyWithImpl<_ExtractedReceiptFields>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExtractedReceiptFieldsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExtractedReceiptFields&&(identical(other.stationName, stationName) || other.stationName == stationName)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.fuelApiValue, fuelApiValue) || other.fuelApiValue == fuelApiValue)&&(identical(other.litres, litres) || other.litres == litres)&&(identical(other.pricePerLitre, pricePerLitre) || other.pricePerLitre == pricePerLitre)&&(identical(other.total, total) || other.total == total)&&(identical(other.vat, vat) || other.vat == vat)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.paymentReference, paymentReference) || other.paymentReference == paymentReference)&&(identical(other.odometerKm, odometerKm) || other.odometerKm == odometerKm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stationName,occurredAt,fuelApiValue,litres,pricePerLitre,total,vat,vatRate,paymentReference,odometerKm);

@override
String toString() {
  return 'ExtractedReceiptFields(stationName: $stationName, occurredAt: $occurredAt, fuelApiValue: $fuelApiValue, litres: $litres, pricePerLitre: $pricePerLitre, total: $total, vat: $vat, vatRate: $vatRate, paymentReference: $paymentReference, odometerKm: $odometerKm)';
}


}

/// @nodoc
abstract mixin class _$ExtractedReceiptFieldsCopyWith<$Res> implements $ExtractedReceiptFieldsCopyWith<$Res> {
  factory _$ExtractedReceiptFieldsCopyWith(_ExtractedReceiptFields value, $Res Function(_ExtractedReceiptFields) _then) = __$ExtractedReceiptFieldsCopyWithImpl;
@override @useResult
$Res call({
 String? stationName, DateTime? occurredAt, String? fuelApiValue, double? litres, double? pricePerLitre, Money? total, Money? vat, double? vatRate, String? paymentReference, double? odometerKm
});




}
/// @nodoc
class __$ExtractedReceiptFieldsCopyWithImpl<$Res>
    implements _$ExtractedReceiptFieldsCopyWith<$Res> {
  __$ExtractedReceiptFieldsCopyWithImpl(this._self, this._then);

  final _ExtractedReceiptFields _self;
  final $Res Function(_ExtractedReceiptFields) _then;

/// Create a copy of ExtractedReceiptFields
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stationName = freezed,Object? occurredAt = freezed,Object? fuelApiValue = freezed,Object? litres = freezed,Object? pricePerLitre = freezed,Object? total = freezed,Object? vat = freezed,Object? vatRate = freezed,Object? paymentReference = freezed,Object? odometerKm = freezed,}) {
  return _then(_ExtractedReceiptFields(
stationName: freezed == stationName ? _self.stationName : stationName // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,fuelApiValue: freezed == fuelApiValue ? _self.fuelApiValue : fuelApiValue // ignore: cast_nullable_to_non_nullable
as String?,litres: freezed == litres ? _self.litres : litres // ignore: cast_nullable_to_non_nullable
as double?,pricePerLitre: freezed == pricePerLitre ? _self.pricePerLitre : pricePerLitre // ignore: cast_nullable_to_non_nullable
as double?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Money?,vat: freezed == vat ? _self.vat : vat // ignore: cast_nullable_to_non_nullable
as Money?,vatRate: freezed == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as double?,paymentReference: freezed == paymentReference ? _self.paymentReference : paymentReference // ignore: cast_nullable_to_non_nullable
as String?,odometerKm: freezed == odometerKm ? _self.odometerKm : odometerKm // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$FieldCorrection {

/// The [ExtractedReceiptFields] field name that changed.
 String get field;/// The machine's value, as it was rendered. Null when the machine
/// read nothing and the employee supplied the field.
 String? get before;/// The employee's value. Null when they cleared the field.
 String? get after;/// When the correction was made — from the injected clock, in UTC.
 DateTime get correctedAt;/// Who made it.
 String get correctedBy;
/// Create a copy of FieldCorrection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldCorrectionCopyWith<FieldCorrection> get copyWith => _$FieldCorrectionCopyWithImpl<FieldCorrection>(this as FieldCorrection, _$identity);

  /// Serializes this FieldCorrection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldCorrection&&(identical(other.field, field) || other.field == field)&&(identical(other.before, before) || other.before == before)&&(identical(other.after, after) || other.after == after)&&(identical(other.correctedAt, correctedAt) || other.correctedAt == correctedAt)&&(identical(other.correctedBy, correctedBy) || other.correctedBy == correctedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,field,before,after,correctedAt,correctedBy);

@override
String toString() {
  return 'FieldCorrection(field: $field, before: $before, after: $after, correctedAt: $correctedAt, correctedBy: $correctedBy)';
}


}

/// @nodoc
abstract mixin class $FieldCorrectionCopyWith<$Res>  {
  factory $FieldCorrectionCopyWith(FieldCorrection value, $Res Function(FieldCorrection) _then) = _$FieldCorrectionCopyWithImpl;
@useResult
$Res call({
 String field, String? before, String? after, DateTime correctedAt, String correctedBy
});




}
/// @nodoc
class _$FieldCorrectionCopyWithImpl<$Res>
    implements $FieldCorrectionCopyWith<$Res> {
  _$FieldCorrectionCopyWithImpl(this._self, this._then);

  final FieldCorrection _self;
  final $Res Function(FieldCorrection) _then;

/// Create a copy of FieldCorrection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? field = null,Object? before = freezed,Object? after = freezed,Object? correctedAt = null,Object? correctedBy = null,}) {
  return _then(_self.copyWith(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,before: freezed == before ? _self.before : before // ignore: cast_nullable_to_non_nullable
as String?,after: freezed == after ? _self.after : after // ignore: cast_nullable_to_non_nullable
as String?,correctedAt: null == correctedAt ? _self.correctedAt : correctedAt // ignore: cast_nullable_to_non_nullable
as DateTime,correctedBy: null == correctedBy ? _self.correctedBy : correctedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FieldCorrection].
extension FieldCorrectionPatterns on FieldCorrection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldCorrection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldCorrection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldCorrection value)  $default,){
final _that = this;
switch (_that) {
case _FieldCorrection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldCorrection value)?  $default,){
final _that = this;
switch (_that) {
case _FieldCorrection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String field,  String? before,  String? after,  DateTime correctedAt,  String correctedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldCorrection() when $default != null:
return $default(_that.field,_that.before,_that.after,_that.correctedAt,_that.correctedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String field,  String? before,  String? after,  DateTime correctedAt,  String correctedBy)  $default,) {final _that = this;
switch (_that) {
case _FieldCorrection():
return $default(_that.field,_that.before,_that.after,_that.correctedAt,_that.correctedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String field,  String? before,  String? after,  DateTime correctedAt,  String correctedBy)?  $default,) {final _that = this;
switch (_that) {
case _FieldCorrection() when $default != null:
return $default(_that.field,_that.before,_that.after,_that.correctedAt,_that.correctedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FieldCorrection implements FieldCorrection {
  const _FieldCorrection({required this.field, this.before, this.after, required this.correctedAt, required this.correctedBy});
  factory _FieldCorrection.fromJson(Map<String, dynamic> json) => _$FieldCorrectionFromJson(json);

/// The [ExtractedReceiptFields] field name that changed.
@override final  String field;
/// The machine's value, as it was rendered. Null when the machine
/// read nothing and the employee supplied the field.
@override final  String? before;
/// The employee's value. Null when they cleared the field.
@override final  String? after;
/// When the correction was made — from the injected clock, in UTC.
@override final  DateTime correctedAt;
/// Who made it.
@override final  String correctedBy;

/// Create a copy of FieldCorrection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldCorrectionCopyWith<_FieldCorrection> get copyWith => __$FieldCorrectionCopyWithImpl<_FieldCorrection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FieldCorrectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldCorrection&&(identical(other.field, field) || other.field == field)&&(identical(other.before, before) || other.before == before)&&(identical(other.after, after) || other.after == after)&&(identical(other.correctedAt, correctedAt) || other.correctedAt == correctedAt)&&(identical(other.correctedBy, correctedBy) || other.correctedBy == correctedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,field,before,after,correctedAt,correctedBy);

@override
String toString() {
  return 'FieldCorrection(field: $field, before: $before, after: $after, correctedAt: $correctedAt, correctedBy: $correctedBy)';
}


}

/// @nodoc
abstract mixin class _$FieldCorrectionCopyWith<$Res> implements $FieldCorrectionCopyWith<$Res> {
  factory _$FieldCorrectionCopyWith(_FieldCorrection value, $Res Function(_FieldCorrection) _then) = __$FieldCorrectionCopyWithImpl;
@override @useResult
$Res call({
 String field, String? before, String? after, DateTime correctedAt, String correctedBy
});




}
/// @nodoc
class __$FieldCorrectionCopyWithImpl<$Res>
    implements _$FieldCorrectionCopyWith<$Res> {
  __$FieldCorrectionCopyWithImpl(this._self, this._then);

  final _FieldCorrection _self;
  final $Res Function(_FieldCorrection) _then;

/// Create a copy of FieldCorrection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field = null,Object? before = freezed,Object? after = freezed,Object? correctedAt = null,Object? correctedBy = null,}) {
  return _then(_FieldCorrection(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,before: freezed == before ? _self.before : before // ignore: cast_nullable_to_non_nullable
as String?,after: freezed == after ? _self.after : after // ignore: cast_nullable_to_non_nullable
as String?,correctedAt: null == correctedAt ? _self.correctedAt : correctedAt // ignore: cast_nullable_to_non_nullable
as DateTime,correctedBy: null == correctedBy ? _self.correctedBy : correctedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
