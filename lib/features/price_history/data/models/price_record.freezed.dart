// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'price_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PriceRecord {

 String get stationId; DateTime get recordedAt; double? get e5; double? get e10; double? get e98; double? get diesel; double? get dieselPremium; double? get e85; double? get lpg; double? get cng;
/// Create a copy of PriceRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceRecordCopyWith<PriceRecord> get copyWith => _$PriceRecordCopyWithImpl<PriceRecord>(this as PriceRecord, _$identity);

  /// Serializes this PriceRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceRecord&&(identical(other.stationId, stationId) || other.stationId == stationId)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.e5, e5) || other.e5 == e5)&&(identical(other.e10, e10) || other.e10 == e10)&&(identical(other.e98, e98) || other.e98 == e98)&&(identical(other.diesel, diesel) || other.diesel == diesel)&&(identical(other.dieselPremium, dieselPremium) || other.dieselPremium == dieselPremium)&&(identical(other.e85, e85) || other.e85 == e85)&&(identical(other.lpg, lpg) || other.lpg == lpg)&&(identical(other.cng, cng) || other.cng == cng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stationId,recordedAt,e5,e10,e98,diesel,dieselPremium,e85,lpg,cng);

@override
String toString() {
  return 'PriceRecord(stationId: $stationId, recordedAt: $recordedAt, e5: $e5, e10: $e10, e98: $e98, diesel: $diesel, dieselPremium: $dieselPremium, e85: $e85, lpg: $lpg, cng: $cng)';
}


}

/// @nodoc
abstract mixin class $PriceRecordCopyWith<$Res>  {
  factory $PriceRecordCopyWith(PriceRecord value, $Res Function(PriceRecord) _then) = _$PriceRecordCopyWithImpl;
@useResult
$Res call({
 String stationId, DateTime recordedAt, double? e5, double? e10, double? e98, double? diesel, double? dieselPremium, double? e85, double? lpg, double? cng
});




}
/// @nodoc
class _$PriceRecordCopyWithImpl<$Res>
    implements $PriceRecordCopyWith<$Res> {
  _$PriceRecordCopyWithImpl(this._self, this._then);

  final PriceRecord _self;
  final $Res Function(PriceRecord) _then;

/// Create a copy of PriceRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stationId = null,Object? recordedAt = null,Object? e5 = freezed,Object? e10 = freezed,Object? e98 = freezed,Object? diesel = freezed,Object? dieselPremium = freezed,Object? e85 = freezed,Object? lpg = freezed,Object? cng = freezed,}) {
  return _then(_self.copyWith(
stationId: null == stationId ? _self.stationId : stationId // ignore: cast_nullable_to_non_nullable
as String,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,e5: freezed == e5 ? _self.e5 : e5 // ignore: cast_nullable_to_non_nullable
as double?,e10: freezed == e10 ? _self.e10 : e10 // ignore: cast_nullable_to_non_nullable
as double?,e98: freezed == e98 ? _self.e98 : e98 // ignore: cast_nullable_to_non_nullable
as double?,diesel: freezed == diesel ? _self.diesel : diesel // ignore: cast_nullable_to_non_nullable
as double?,dieselPremium: freezed == dieselPremium ? _self.dieselPremium : dieselPremium // ignore: cast_nullable_to_non_nullable
as double?,e85: freezed == e85 ? _self.e85 : e85 // ignore: cast_nullable_to_non_nullable
as double?,lpg: freezed == lpg ? _self.lpg : lpg // ignore: cast_nullable_to_non_nullable
as double?,cng: freezed == cng ? _self.cng : cng // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PriceRecord].
extension PriceRecordPatterns on PriceRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriceRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriceRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriceRecord value)  $default,){
final _that = this;
switch (_that) {
case _PriceRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriceRecord value)?  $default,){
final _that = this;
switch (_that) {
case _PriceRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String stationId,  DateTime recordedAt,  double? e5,  double? e10,  double? e98,  double? diesel,  double? dieselPremium,  double? e85,  double? lpg,  double? cng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriceRecord() when $default != null:
return $default(_that.stationId,_that.recordedAt,_that.e5,_that.e10,_that.e98,_that.diesel,_that.dieselPremium,_that.e85,_that.lpg,_that.cng);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String stationId,  DateTime recordedAt,  double? e5,  double? e10,  double? e98,  double? diesel,  double? dieselPremium,  double? e85,  double? lpg,  double? cng)  $default,) {final _that = this;
switch (_that) {
case _PriceRecord():
return $default(_that.stationId,_that.recordedAt,_that.e5,_that.e10,_that.e98,_that.diesel,_that.dieselPremium,_that.e85,_that.lpg,_that.cng);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String stationId,  DateTime recordedAt,  double? e5,  double? e10,  double? e98,  double? diesel,  double? dieselPremium,  double? e85,  double? lpg,  double? cng)?  $default,) {final _that = this;
switch (_that) {
case _PriceRecord() when $default != null:
return $default(_that.stationId,_that.recordedAt,_that.e5,_that.e10,_that.e98,_that.diesel,_that.dieselPremium,_that.e85,_that.lpg,_that.cng);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PriceRecord implements PriceRecord {
  const _PriceRecord({required this.stationId, required this.recordedAt, this.e5, this.e10, this.e98, this.diesel, this.dieselPremium, this.e85, this.lpg, this.cng});
  factory _PriceRecord.fromJson(Map<String, dynamic> json) => _$PriceRecordFromJson(json);

@override final  String stationId;
@override final  DateTime recordedAt;
@override final  double? e5;
@override final  double? e10;
@override final  double? e98;
@override final  double? diesel;
@override final  double? dieselPremium;
@override final  double? e85;
@override final  double? lpg;
@override final  double? cng;

/// Create a copy of PriceRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceRecordCopyWith<_PriceRecord> get copyWith => __$PriceRecordCopyWithImpl<_PriceRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PriceRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceRecord&&(identical(other.stationId, stationId) || other.stationId == stationId)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.e5, e5) || other.e5 == e5)&&(identical(other.e10, e10) || other.e10 == e10)&&(identical(other.e98, e98) || other.e98 == e98)&&(identical(other.diesel, diesel) || other.diesel == diesel)&&(identical(other.dieselPremium, dieselPremium) || other.dieselPremium == dieselPremium)&&(identical(other.e85, e85) || other.e85 == e85)&&(identical(other.lpg, lpg) || other.lpg == lpg)&&(identical(other.cng, cng) || other.cng == cng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stationId,recordedAt,e5,e10,e98,diesel,dieselPremium,e85,lpg,cng);

@override
String toString() {
  return 'PriceRecord(stationId: $stationId, recordedAt: $recordedAt, e5: $e5, e10: $e10, e98: $e98, diesel: $diesel, dieselPremium: $dieselPremium, e85: $e85, lpg: $lpg, cng: $cng)';
}


}

/// @nodoc
abstract mixin class _$PriceRecordCopyWith<$Res> implements $PriceRecordCopyWith<$Res> {
  factory _$PriceRecordCopyWith(_PriceRecord value, $Res Function(_PriceRecord) _then) = __$PriceRecordCopyWithImpl;
@override @useResult
$Res call({
 String stationId, DateTime recordedAt, double? e5, double? e10, double? e98, double? diesel, double? dieselPremium, double? e85, double? lpg, double? cng
});




}
/// @nodoc
class __$PriceRecordCopyWithImpl<$Res>
    implements _$PriceRecordCopyWith<$Res> {
  __$PriceRecordCopyWithImpl(this._self, this._then);

  final _PriceRecord _self;
  final $Res Function(_PriceRecord) _then;

/// Create a copy of PriceRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stationId = null,Object? recordedAt = null,Object? e5 = freezed,Object? e10 = freezed,Object? e98 = freezed,Object? diesel = freezed,Object? dieselPremium = freezed,Object? e85 = freezed,Object? lpg = freezed,Object? cng = freezed,}) {
  return _then(_PriceRecord(
stationId: null == stationId ? _self.stationId : stationId // ignore: cast_nullable_to_non_nullable
as String,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,e5: freezed == e5 ? _self.e5 : e5 // ignore: cast_nullable_to_non_nullable
as double?,e10: freezed == e10 ? _self.e10 : e10 // ignore: cast_nullable_to_non_nullable
as double?,e98: freezed == e98 ? _self.e98 : e98 // ignore: cast_nullable_to_non_nullable
as double?,diesel: freezed == diesel ? _self.diesel : diesel // ignore: cast_nullable_to_non_nullable
as double?,dieselPremium: freezed == dieselPremium ? _self.dieselPremium : dieselPremium // ignore: cast_nullable_to_non_nullable
as double?,e85: freezed == e85 ? _self.e85 : e85 // ignore: cast_nullable_to_non_nullable
as double?,lpg: freezed == lpg ? _self.lpg : lpg // ignore: cast_nullable_to_non_nullable
as double?,cng: freezed == cng ? _self.cng : cng // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
