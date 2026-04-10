// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'charging_tariff.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TariffComponent {

@PriceComponentTypeJsonConverter() PriceComponentType get type; double get price; int get stepSize;
/// Create a copy of TariffComponent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TariffComponentCopyWith<TariffComponent> get copyWith => _$TariffComponentCopyWithImpl<TariffComponent>(this as TariffComponent, _$identity);

  /// Serializes this TariffComponent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TariffComponent&&(identical(other.type, type) || other.type == type)&&(identical(other.price, price) || other.price == price)&&(identical(other.stepSize, stepSize) || other.stepSize == stepSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,price,stepSize);

@override
String toString() {
  return 'TariffComponent(type: $type, price: $price, stepSize: $stepSize)';
}


}

/// @nodoc
abstract mixin class $TariffComponentCopyWith<$Res>  {
  factory $TariffComponentCopyWith(TariffComponent value, $Res Function(TariffComponent) _then) = _$TariffComponentCopyWithImpl;
@useResult
$Res call({
@PriceComponentTypeJsonConverter() PriceComponentType type, double price, int stepSize
});




}
/// @nodoc
class _$TariffComponentCopyWithImpl<$Res>
    implements $TariffComponentCopyWith<$Res> {
  _$TariffComponentCopyWithImpl(this._self, this._then);

  final TariffComponent _self;
  final $Res Function(TariffComponent) _then;

/// Create a copy of TariffComponent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? price = null,Object? stepSize = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PriceComponentType,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,stepSize: null == stepSize ? _self.stepSize : stepSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TariffComponent].
extension TariffComponentPatterns on TariffComponent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TariffComponent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TariffComponent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TariffComponent value)  $default,){
final _that = this;
switch (_that) {
case _TariffComponent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TariffComponent value)?  $default,){
final _that = this;
switch (_that) {
case _TariffComponent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@PriceComponentTypeJsonConverter()  PriceComponentType type,  double price,  int stepSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TariffComponent() when $default != null:
return $default(_that.type,_that.price,_that.stepSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@PriceComponentTypeJsonConverter()  PriceComponentType type,  double price,  int stepSize)  $default,) {final _that = this;
switch (_that) {
case _TariffComponent():
return $default(_that.type,_that.price,_that.stepSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@PriceComponentTypeJsonConverter()  PriceComponentType type,  double price,  int stepSize)?  $default,) {final _that = this;
switch (_that) {
case _TariffComponent() when $default != null:
return $default(_that.type,_that.price,_that.stepSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TariffComponent implements TariffComponent {
  const _TariffComponent({@PriceComponentTypeJsonConverter() this.type = PriceComponentType.energy, this.price = 0, this.stepSize = 1});
  factory _TariffComponent.fromJson(Map<String, dynamic> json) => _$TariffComponentFromJson(json);

@override@JsonKey()@PriceComponentTypeJsonConverter() final  PriceComponentType type;
@override@JsonKey() final  double price;
@override@JsonKey() final  int stepSize;

/// Create a copy of TariffComponent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TariffComponentCopyWith<_TariffComponent> get copyWith => __$TariffComponentCopyWithImpl<_TariffComponent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TariffComponentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TariffComponent&&(identical(other.type, type) || other.type == type)&&(identical(other.price, price) || other.price == price)&&(identical(other.stepSize, stepSize) || other.stepSize == stepSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,price,stepSize);

@override
String toString() {
  return 'TariffComponent(type: $type, price: $price, stepSize: $stepSize)';
}


}

/// @nodoc
abstract mixin class _$TariffComponentCopyWith<$Res> implements $TariffComponentCopyWith<$Res> {
  factory _$TariffComponentCopyWith(_TariffComponent value, $Res Function(_TariffComponent) _then) = __$TariffComponentCopyWithImpl;
@override @useResult
$Res call({
@PriceComponentTypeJsonConverter() PriceComponentType type, double price, int stepSize
});




}
/// @nodoc
class __$TariffComponentCopyWithImpl<$Res>
    implements _$TariffComponentCopyWith<$Res> {
  __$TariffComponentCopyWithImpl(this._self, this._then);

  final _TariffComponent _self;
  final $Res Function(_TariffComponent) _then;

/// Create a copy of TariffComponent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? price = null,Object? stepSize = null,}) {
  return _then(_TariffComponent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PriceComponentType,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,stepSize: null == stepSize ? _self.stepSize : stepSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TariffRestriction {

 String? get startTime; String? get endTime; List<int> get daysOfWeek; double? get minKwh; double? get maxKwh;
/// Create a copy of TariffRestriction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TariffRestrictionCopyWith<TariffRestriction> get copyWith => _$TariffRestrictionCopyWithImpl<TariffRestriction>(this as TariffRestriction, _$identity);

  /// Serializes this TariffRestriction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TariffRestriction&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&const DeepCollectionEquality().equals(other.daysOfWeek, daysOfWeek)&&(identical(other.minKwh, minKwh) || other.minKwh == minKwh)&&(identical(other.maxKwh, maxKwh) || other.maxKwh == maxKwh));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startTime,endTime,const DeepCollectionEquality().hash(daysOfWeek),minKwh,maxKwh);

@override
String toString() {
  return 'TariffRestriction(startTime: $startTime, endTime: $endTime, daysOfWeek: $daysOfWeek, minKwh: $minKwh, maxKwh: $maxKwh)';
}


}

/// @nodoc
abstract mixin class $TariffRestrictionCopyWith<$Res>  {
  factory $TariffRestrictionCopyWith(TariffRestriction value, $Res Function(TariffRestriction) _then) = _$TariffRestrictionCopyWithImpl;
@useResult
$Res call({
 String? startTime, String? endTime, List<int> daysOfWeek, double? minKwh, double? maxKwh
});




}
/// @nodoc
class _$TariffRestrictionCopyWithImpl<$Res>
    implements $TariffRestrictionCopyWith<$Res> {
  _$TariffRestrictionCopyWithImpl(this._self, this._then);

  final TariffRestriction _self;
  final $Res Function(TariffRestriction) _then;

/// Create a copy of TariffRestriction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startTime = freezed,Object? endTime = freezed,Object? daysOfWeek = null,Object? minKwh = freezed,Object? maxKwh = freezed,}) {
  return _then(_self.copyWith(
startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,daysOfWeek: null == daysOfWeek ? _self.daysOfWeek : daysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,minKwh: freezed == minKwh ? _self.minKwh : minKwh // ignore: cast_nullable_to_non_nullable
as double?,maxKwh: freezed == maxKwh ? _self.maxKwh : maxKwh // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [TariffRestriction].
extension TariffRestrictionPatterns on TariffRestriction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TariffRestriction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TariffRestriction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TariffRestriction value)  $default,){
final _that = this;
switch (_that) {
case _TariffRestriction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TariffRestriction value)?  $default,){
final _that = this;
switch (_that) {
case _TariffRestriction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? startTime,  String? endTime,  List<int> daysOfWeek,  double? minKwh,  double? maxKwh)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TariffRestriction() when $default != null:
return $default(_that.startTime,_that.endTime,_that.daysOfWeek,_that.minKwh,_that.maxKwh);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? startTime,  String? endTime,  List<int> daysOfWeek,  double? minKwh,  double? maxKwh)  $default,) {final _that = this;
switch (_that) {
case _TariffRestriction():
return $default(_that.startTime,_that.endTime,_that.daysOfWeek,_that.minKwh,_that.maxKwh);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? startTime,  String? endTime,  List<int> daysOfWeek,  double? minKwh,  double? maxKwh)?  $default,) {final _that = this;
switch (_that) {
case _TariffRestriction() when $default != null:
return $default(_that.startTime,_that.endTime,_that.daysOfWeek,_that.minKwh,_that.maxKwh);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TariffRestriction implements TariffRestriction {
  const _TariffRestriction({this.startTime, this.endTime, final  List<int> daysOfWeek = const <int>[], this.minKwh, this.maxKwh}): _daysOfWeek = daysOfWeek;
  factory _TariffRestriction.fromJson(Map<String, dynamic> json) => _$TariffRestrictionFromJson(json);

@override final  String? startTime;
@override final  String? endTime;
 final  List<int> _daysOfWeek;
@override@JsonKey() List<int> get daysOfWeek {
  if (_daysOfWeek is EqualUnmodifiableListView) return _daysOfWeek;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_daysOfWeek);
}

@override final  double? minKwh;
@override final  double? maxKwh;

/// Create a copy of TariffRestriction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TariffRestrictionCopyWith<_TariffRestriction> get copyWith => __$TariffRestrictionCopyWithImpl<_TariffRestriction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TariffRestrictionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TariffRestriction&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&const DeepCollectionEquality().equals(other._daysOfWeek, _daysOfWeek)&&(identical(other.minKwh, minKwh) || other.minKwh == minKwh)&&(identical(other.maxKwh, maxKwh) || other.maxKwh == maxKwh));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startTime,endTime,const DeepCollectionEquality().hash(_daysOfWeek),minKwh,maxKwh);

@override
String toString() {
  return 'TariffRestriction(startTime: $startTime, endTime: $endTime, daysOfWeek: $daysOfWeek, minKwh: $minKwh, maxKwh: $maxKwh)';
}


}

/// @nodoc
abstract mixin class _$TariffRestrictionCopyWith<$Res> implements $TariffRestrictionCopyWith<$Res> {
  factory _$TariffRestrictionCopyWith(_TariffRestriction value, $Res Function(_TariffRestriction) _then) = __$TariffRestrictionCopyWithImpl;
@override @useResult
$Res call({
 String? startTime, String? endTime, List<int> daysOfWeek, double? minKwh, double? maxKwh
});




}
/// @nodoc
class __$TariffRestrictionCopyWithImpl<$Res>
    implements _$TariffRestrictionCopyWith<$Res> {
  __$TariffRestrictionCopyWithImpl(this._self, this._then);

  final _TariffRestriction _self;
  final $Res Function(_TariffRestriction) _then;

/// Create a copy of TariffRestriction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startTime = freezed,Object? endTime = freezed,Object? daysOfWeek = null,Object? minKwh = freezed,Object? maxKwh = freezed,}) {
  return _then(_TariffRestriction(
startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,daysOfWeek: null == daysOfWeek ? _self._daysOfWeek : daysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,minKwh: freezed == minKwh ? _self.minKwh : minKwh // ignore: cast_nullable_to_non_nullable
as double?,maxKwh: freezed == maxKwh ? _self.maxKwh : maxKwh // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$TariffElement {

@TariffComponentListConverter() List<TariffComponent> get priceComponents;@TariffRestrictionNullableConverter() TariffRestriction? get restrictions;
/// Create a copy of TariffElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TariffElementCopyWith<TariffElement> get copyWith => _$TariffElementCopyWithImpl<TariffElement>(this as TariffElement, _$identity);

  /// Serializes this TariffElement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TariffElement&&const DeepCollectionEquality().equals(other.priceComponents, priceComponents)&&(identical(other.restrictions, restrictions) || other.restrictions == restrictions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(priceComponents),restrictions);

@override
String toString() {
  return 'TariffElement(priceComponents: $priceComponents, restrictions: $restrictions)';
}


}

/// @nodoc
abstract mixin class $TariffElementCopyWith<$Res>  {
  factory $TariffElementCopyWith(TariffElement value, $Res Function(TariffElement) _then) = _$TariffElementCopyWithImpl;
@useResult
$Res call({
@TariffComponentListConverter() List<TariffComponent> priceComponents,@TariffRestrictionNullableConverter() TariffRestriction? restrictions
});


$TariffRestrictionCopyWith<$Res>? get restrictions;

}
/// @nodoc
class _$TariffElementCopyWithImpl<$Res>
    implements $TariffElementCopyWith<$Res> {
  _$TariffElementCopyWithImpl(this._self, this._then);

  final TariffElement _self;
  final $Res Function(TariffElement) _then;

/// Create a copy of TariffElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? priceComponents = null,Object? restrictions = freezed,}) {
  return _then(_self.copyWith(
priceComponents: null == priceComponents ? _self.priceComponents : priceComponents // ignore: cast_nullable_to_non_nullable
as List<TariffComponent>,restrictions: freezed == restrictions ? _self.restrictions : restrictions // ignore: cast_nullable_to_non_nullable
as TariffRestriction?,
  ));
}
/// Create a copy of TariffElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TariffRestrictionCopyWith<$Res>? get restrictions {
    if (_self.restrictions == null) {
    return null;
  }

  return $TariffRestrictionCopyWith<$Res>(_self.restrictions!, (value) {
    return _then(_self.copyWith(restrictions: value));
  });
}
}


/// Adds pattern-matching-related methods to [TariffElement].
extension TariffElementPatterns on TariffElement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TariffElement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TariffElement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TariffElement value)  $default,){
final _that = this;
switch (_that) {
case _TariffElement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TariffElement value)?  $default,){
final _that = this;
switch (_that) {
case _TariffElement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@TariffComponentListConverter()  List<TariffComponent> priceComponents, @TariffRestrictionNullableConverter()  TariffRestriction? restrictions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TariffElement() when $default != null:
return $default(_that.priceComponents,_that.restrictions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@TariffComponentListConverter()  List<TariffComponent> priceComponents, @TariffRestrictionNullableConverter()  TariffRestriction? restrictions)  $default,) {final _that = this;
switch (_that) {
case _TariffElement():
return $default(_that.priceComponents,_that.restrictions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@TariffComponentListConverter()  List<TariffComponent> priceComponents, @TariffRestrictionNullableConverter()  TariffRestriction? restrictions)?  $default,) {final _that = this;
switch (_that) {
case _TariffElement() when $default != null:
return $default(_that.priceComponents,_that.restrictions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TariffElement implements TariffElement {
  const _TariffElement({@TariffComponentListConverter() final  List<TariffComponent> priceComponents = const <TariffComponent>[], @TariffRestrictionNullableConverter() this.restrictions}): _priceComponents = priceComponents;
  factory _TariffElement.fromJson(Map<String, dynamic> json) => _$TariffElementFromJson(json);

 final  List<TariffComponent> _priceComponents;
@override@JsonKey()@TariffComponentListConverter() List<TariffComponent> get priceComponents {
  if (_priceComponents is EqualUnmodifiableListView) return _priceComponents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_priceComponents);
}

@override@TariffRestrictionNullableConverter() final  TariffRestriction? restrictions;

/// Create a copy of TariffElement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TariffElementCopyWith<_TariffElement> get copyWith => __$TariffElementCopyWithImpl<_TariffElement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TariffElementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TariffElement&&const DeepCollectionEquality().equals(other._priceComponents, _priceComponents)&&(identical(other.restrictions, restrictions) || other.restrictions == restrictions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_priceComponents),restrictions);

@override
String toString() {
  return 'TariffElement(priceComponents: $priceComponents, restrictions: $restrictions)';
}


}

/// @nodoc
abstract mixin class _$TariffElementCopyWith<$Res> implements $TariffElementCopyWith<$Res> {
  factory _$TariffElementCopyWith(_TariffElement value, $Res Function(_TariffElement) _then) = __$TariffElementCopyWithImpl;
@override @useResult
$Res call({
@TariffComponentListConverter() List<TariffComponent> priceComponents,@TariffRestrictionNullableConverter() TariffRestriction? restrictions
});


@override $TariffRestrictionCopyWith<$Res>? get restrictions;

}
/// @nodoc
class __$TariffElementCopyWithImpl<$Res>
    implements _$TariffElementCopyWith<$Res> {
  __$TariffElementCopyWithImpl(this._self, this._then);

  final _TariffElement _self;
  final $Res Function(_TariffElement) _then;

/// Create a copy of TariffElement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? priceComponents = null,Object? restrictions = freezed,}) {
  return _then(_TariffElement(
priceComponents: null == priceComponents ? _self._priceComponents : priceComponents // ignore: cast_nullable_to_non_nullable
as List<TariffComponent>,restrictions: freezed == restrictions ? _self.restrictions : restrictions // ignore: cast_nullable_to_non_nullable
as TariffRestriction?,
  ));
}

/// Create a copy of TariffElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TariffRestrictionCopyWith<$Res>? get restrictions {
    if (_self.restrictions == null) {
    return null;
  }

  return $TariffRestrictionCopyWith<$Res>(_self.restrictions!, (value) {
    return _then(_self.copyWith(restrictions: value));
  });
}
}


/// @nodoc
mixin _$ChargingTariff {

 String get id; String get currency;@TariffTypeJsonConverter() TariffType get type;@TariffElementListConverter() List<TariffElement> get elements; DateTime? get validFrom; DateTime? get validTo;
/// Create a copy of ChargingTariff
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChargingTariffCopyWith<ChargingTariff> get copyWith => _$ChargingTariffCopyWithImpl<ChargingTariff>(this as ChargingTariff, _$identity);

  /// Serializes this ChargingTariff to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChargingTariff&&(identical(other.id, id) || other.id == id)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.elements, elements)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validTo, validTo) || other.validTo == validTo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,currency,type,const DeepCollectionEquality().hash(elements),validFrom,validTo);

@override
String toString() {
  return 'ChargingTariff(id: $id, currency: $currency, type: $type, elements: $elements, validFrom: $validFrom, validTo: $validTo)';
}


}

/// @nodoc
abstract mixin class $ChargingTariffCopyWith<$Res>  {
  factory $ChargingTariffCopyWith(ChargingTariff value, $Res Function(ChargingTariff) _then) = _$ChargingTariffCopyWithImpl;
@useResult
$Res call({
 String id, String currency,@TariffTypeJsonConverter() TariffType type,@TariffElementListConverter() List<TariffElement> elements, DateTime? validFrom, DateTime? validTo
});




}
/// @nodoc
class _$ChargingTariffCopyWithImpl<$Res>
    implements $ChargingTariffCopyWith<$Res> {
  _$ChargingTariffCopyWithImpl(this._self, this._then);

  final ChargingTariff _self;
  final $Res Function(ChargingTariff) _then;

/// Create a copy of ChargingTariff
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? currency = null,Object? type = null,Object? elements = null,Object? validFrom = freezed,Object? validTo = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TariffType,elements: null == elements ? _self.elements : elements // ignore: cast_nullable_to_non_nullable
as List<TariffElement>,validFrom: freezed == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,validTo: freezed == validTo ? _self.validTo : validTo // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChargingTariff].
extension ChargingTariffPatterns on ChargingTariff {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChargingTariff value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChargingTariff() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChargingTariff value)  $default,){
final _that = this;
switch (_that) {
case _ChargingTariff():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChargingTariff value)?  $default,){
final _that = this;
switch (_that) {
case _ChargingTariff() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String currency, @TariffTypeJsonConverter()  TariffType type, @TariffElementListConverter()  List<TariffElement> elements,  DateTime? validFrom,  DateTime? validTo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChargingTariff() when $default != null:
return $default(_that.id,_that.currency,_that.type,_that.elements,_that.validFrom,_that.validTo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String currency, @TariffTypeJsonConverter()  TariffType type, @TariffElementListConverter()  List<TariffElement> elements,  DateTime? validFrom,  DateTime? validTo)  $default,) {final _that = this;
switch (_that) {
case _ChargingTariff():
return $default(_that.id,_that.currency,_that.type,_that.elements,_that.validFrom,_that.validTo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String currency, @TariffTypeJsonConverter()  TariffType type, @TariffElementListConverter()  List<TariffElement> elements,  DateTime? validFrom,  DateTime? validTo)?  $default,) {final _that = this;
switch (_that) {
case _ChargingTariff() when $default != null:
return $default(_that.id,_that.currency,_that.type,_that.elements,_that.validFrom,_that.validTo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChargingTariff extends ChargingTariff {
  const _ChargingTariff({required this.id, this.currency = 'EUR', @TariffTypeJsonConverter() this.type = TariffType.regular, @TariffElementListConverter() final  List<TariffElement> elements = const <TariffElement>[], this.validFrom, this.validTo}): _elements = elements,super._();
  factory _ChargingTariff.fromJson(Map<String, dynamic> json) => _$ChargingTariffFromJson(json);

@override final  String id;
@override@JsonKey() final  String currency;
@override@JsonKey()@TariffTypeJsonConverter() final  TariffType type;
 final  List<TariffElement> _elements;
@override@JsonKey()@TariffElementListConverter() List<TariffElement> get elements {
  if (_elements is EqualUnmodifiableListView) return _elements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_elements);
}

@override final  DateTime? validFrom;
@override final  DateTime? validTo;

/// Create a copy of ChargingTariff
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChargingTariffCopyWith<_ChargingTariff> get copyWith => __$ChargingTariffCopyWithImpl<_ChargingTariff>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChargingTariffToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChargingTariff&&(identical(other.id, id) || other.id == id)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._elements, _elements)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validTo, validTo) || other.validTo == validTo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,currency,type,const DeepCollectionEquality().hash(_elements),validFrom,validTo);

@override
String toString() {
  return 'ChargingTariff(id: $id, currency: $currency, type: $type, elements: $elements, validFrom: $validFrom, validTo: $validTo)';
}


}

/// @nodoc
abstract mixin class _$ChargingTariffCopyWith<$Res> implements $ChargingTariffCopyWith<$Res> {
  factory _$ChargingTariffCopyWith(_ChargingTariff value, $Res Function(_ChargingTariff) _then) = __$ChargingTariffCopyWithImpl;
@override @useResult
$Res call({
 String id, String currency,@TariffTypeJsonConverter() TariffType type,@TariffElementListConverter() List<TariffElement> elements, DateTime? validFrom, DateTime? validTo
});




}
/// @nodoc
class __$ChargingTariffCopyWithImpl<$Res>
    implements _$ChargingTariffCopyWith<$Res> {
  __$ChargingTariffCopyWithImpl(this._self, this._then);

  final _ChargingTariff _self;
  final $Res Function(_ChargingTariff) _then;

/// Create a copy of ChargingTariff
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? currency = null,Object? type = null,Object? elements = null,Object? validFrom = freezed,Object? validTo = freezed,}) {
  return _then(_ChargingTariff(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TariffType,elements: null == elements ? _self._elements : elements // ignore: cast_nullable_to_non_nullable
as List<TariffElement>,validFrom: freezed == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,validTo: freezed == validTo ? _self.validTo : validTo // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
