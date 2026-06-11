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
mixin _$TimeRange {

 int get startMinutes; int get endMinutes;
/// Create a copy of TimeRange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeRangeCopyWith<TimeRange> get copyWith => _$TimeRangeCopyWithImpl<TimeRange>(this as TimeRange, _$identity);

  /// Serializes this TimeRange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeRange&&(identical(other.startMinutes, startMinutes) || other.startMinutes == startMinutes)&&(identical(other.endMinutes, endMinutes) || other.endMinutes == endMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startMinutes,endMinutes);

@override
String toString() {
  return 'TimeRange(startMinutes: $startMinutes, endMinutes: $endMinutes)';
}


}

/// @nodoc
abstract mixin class $TimeRangeCopyWith<$Res>  {
  factory $TimeRangeCopyWith(TimeRange value, $Res Function(TimeRange) _then) = _$TimeRangeCopyWithImpl;
@useResult
$Res call({
 int startMinutes, int endMinutes
});




}
/// @nodoc
class _$TimeRangeCopyWithImpl<$Res>
    implements $TimeRangeCopyWith<$Res> {
  _$TimeRangeCopyWithImpl(this._self, this._then);

  final TimeRange _self;
  final $Res Function(TimeRange) _then;

/// Create a copy of TimeRange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startMinutes = null,Object? endMinutes = null,}) {
  return _then(_self.copyWith(
startMinutes: null == startMinutes ? _self.startMinutes : startMinutes // ignore: cast_nullable_to_non_nullable
as int,endMinutes: null == endMinutes ? _self.endMinutes : endMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TimeRange].
extension TimeRangePatterns on TimeRange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimeRange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimeRange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimeRange value)  $default,){
final _that = this;
switch (_that) {
case _TimeRange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimeRange value)?  $default,){
final _that = this;
switch (_that) {
case _TimeRange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int startMinutes,  int endMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimeRange() when $default != null:
return $default(_that.startMinutes,_that.endMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int startMinutes,  int endMinutes)  $default,) {final _that = this;
switch (_that) {
case _TimeRange():
return $default(_that.startMinutes,_that.endMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int startMinutes,  int endMinutes)?  $default,) {final _that = this;
switch (_that) {
case _TimeRange() when $default != null:
return $default(_that.startMinutes,_that.endMinutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TimeRange extends TimeRange {
  const _TimeRange({required this.startMinutes, required this.endMinutes}): super._();
  factory _TimeRange.fromJson(Map<String, dynamic> json) => _$TimeRangeFromJson(json);

@override final  int startMinutes;
@override final  int endMinutes;

/// Create a copy of TimeRange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimeRangeCopyWith<_TimeRange> get copyWith => __$TimeRangeCopyWithImpl<_TimeRange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimeRangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimeRange&&(identical(other.startMinutes, startMinutes) || other.startMinutes == startMinutes)&&(identical(other.endMinutes, endMinutes) || other.endMinutes == endMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startMinutes,endMinutes);

@override
String toString() {
  return 'TimeRange(startMinutes: $startMinutes, endMinutes: $endMinutes)';
}


}

/// @nodoc
abstract mixin class _$TimeRangeCopyWith<$Res> implements $TimeRangeCopyWith<$Res> {
  factory _$TimeRangeCopyWith(_TimeRange value, $Res Function(_TimeRange) _then) = __$TimeRangeCopyWithImpl;
@override @useResult
$Res call({
 int startMinutes, int endMinutes
});




}
/// @nodoc
class __$TimeRangeCopyWithImpl<$Res>
    implements _$TimeRangeCopyWith<$Res> {
  __$TimeRangeCopyWithImpl(this._self, this._then);

  final _TimeRange _self;
  final $Res Function(_TimeRange) _then;

/// Create a copy of TimeRange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startMinutes = null,Object? endMinutes = null,}) {
  return _then(_TimeRange(
startMinutes: null == startMinutes ? _self.startMinutes : startMinutes // ignore: cast_nullable_to_non_nullable
as int,endMinutes: null == endMinutes ? _self.endMinutes : endMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DayHours {

 OpeningDay get day; DayState get state; List<TimeRange> get ranges;
/// Create a copy of DayHours
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayHoursCopyWith<DayHours> get copyWith => _$DayHoursCopyWithImpl<DayHours>(this as DayHours, _$identity);

  /// Serializes this DayHours to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayHours&&(identical(other.day, day) || other.day == day)&&(identical(other.state, state) || other.state == state)&&const DeepCollectionEquality().equals(other.ranges, ranges));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,day,state,const DeepCollectionEquality().hash(ranges));

@override
String toString() {
  return 'DayHours(day: $day, state: $state, ranges: $ranges)';
}


}

/// @nodoc
abstract mixin class $DayHoursCopyWith<$Res>  {
  factory $DayHoursCopyWith(DayHours value, $Res Function(DayHours) _then) = _$DayHoursCopyWithImpl;
@useResult
$Res call({
 OpeningDay day, DayState state, List<TimeRange> ranges
});




}
/// @nodoc
class _$DayHoursCopyWithImpl<$Res>
    implements $DayHoursCopyWith<$Res> {
  _$DayHoursCopyWithImpl(this._self, this._then);

  final DayHours _self;
  final $Res Function(DayHours) _then;

/// Create a copy of DayHours
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? state = null,Object? ranges = null,}) {
  return _then(_self.copyWith(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as OpeningDay,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as DayState,ranges: null == ranges ? _self.ranges : ranges // ignore: cast_nullable_to_non_nullable
as List<TimeRange>,
  ));
}

}


/// Adds pattern-matching-related methods to [DayHours].
extension DayHoursPatterns on DayHours {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayHours value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayHours() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayHours value)  $default,){
final _that = this;
switch (_that) {
case _DayHours():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayHours value)?  $default,){
final _that = this;
switch (_that) {
case _DayHours() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OpeningDay day,  DayState state,  List<TimeRange> ranges)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayHours() when $default != null:
return $default(_that.day,_that.state,_that.ranges);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OpeningDay day,  DayState state,  List<TimeRange> ranges)  $default,) {final _that = this;
switch (_that) {
case _DayHours():
return $default(_that.day,_that.state,_that.ranges);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OpeningDay day,  DayState state,  List<TimeRange> ranges)?  $default,) {final _that = this;
switch (_that) {
case _DayHours() when $default != null:
return $default(_that.day,_that.state,_that.ranges);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayHours implements DayHours {
  const _DayHours({required this.day, required this.state, final  List<TimeRange> ranges = const []}): _ranges = ranges;
  factory _DayHours.fromJson(Map<String, dynamic> json) => _$DayHoursFromJson(json);

@override final  OpeningDay day;
@override final  DayState state;
 final  List<TimeRange> _ranges;
@override@JsonKey() List<TimeRange> get ranges {
  if (_ranges is EqualUnmodifiableListView) return _ranges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ranges);
}


/// Create a copy of DayHours
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayHoursCopyWith<_DayHours> get copyWith => __$DayHoursCopyWithImpl<_DayHours>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayHoursToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayHours&&(identical(other.day, day) || other.day == day)&&(identical(other.state, state) || other.state == state)&&const DeepCollectionEquality().equals(other._ranges, _ranges));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,day,state,const DeepCollectionEquality().hash(_ranges));

@override
String toString() {
  return 'DayHours(day: $day, state: $state, ranges: $ranges)';
}


}

/// @nodoc
abstract mixin class _$DayHoursCopyWith<$Res> implements $DayHoursCopyWith<$Res> {
  factory _$DayHoursCopyWith(_DayHours value, $Res Function(_DayHours) _then) = __$DayHoursCopyWithImpl;
@override @useResult
$Res call({
 OpeningDay day, DayState state, List<TimeRange> ranges
});




}
/// @nodoc
class __$DayHoursCopyWithImpl<$Res>
    implements _$DayHoursCopyWith<$Res> {
  __$DayHoursCopyWithImpl(this._self, this._then);

  final _DayHours _self;
  final $Res Function(_DayHours) _then;

/// Create a copy of DayHours
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? state = null,Object? ranges = null,}) {
  return _then(_DayHours(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as OpeningDay,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as DayState,ranges: null == ranges ? _self._ranges : ranges // ignore: cast_nullable_to_non_nullable
as List<TimeRange>,
  ));
}


}


/// @nodoc
mixin _$WeeklyOpeningHours {

 List<DayHours> get days; OpeningHoursAvailability get availability; String? get rawSource; bool get automate24h;
/// Create a copy of WeeklyOpeningHours
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyOpeningHoursCopyWith<WeeklyOpeningHours> get copyWith => _$WeeklyOpeningHoursCopyWithImpl<WeeklyOpeningHours>(this as WeeklyOpeningHours, _$identity);

  /// Serializes this WeeklyOpeningHours to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyOpeningHours&&const DeepCollectionEquality().equals(other.days, days)&&(identical(other.availability, availability) || other.availability == availability)&&(identical(other.rawSource, rawSource) || other.rawSource == rawSource)&&(identical(other.automate24h, automate24h) || other.automate24h == automate24h));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(days),availability,rawSource,automate24h);

@override
String toString() {
  return 'WeeklyOpeningHours(days: $days, availability: $availability, rawSource: $rawSource, automate24h: $automate24h)';
}


}

/// @nodoc
abstract mixin class $WeeklyOpeningHoursCopyWith<$Res>  {
  factory $WeeklyOpeningHoursCopyWith(WeeklyOpeningHours value, $Res Function(WeeklyOpeningHours) _then) = _$WeeklyOpeningHoursCopyWithImpl;
@useResult
$Res call({
 List<DayHours> days, OpeningHoursAvailability availability, String? rawSource, bool automate24h
});




}
/// @nodoc
class _$WeeklyOpeningHoursCopyWithImpl<$Res>
    implements $WeeklyOpeningHoursCopyWith<$Res> {
  _$WeeklyOpeningHoursCopyWithImpl(this._self, this._then);

  final WeeklyOpeningHours _self;
  final $Res Function(WeeklyOpeningHours) _then;

/// Create a copy of WeeklyOpeningHours
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? days = null,Object? availability = null,Object? rawSource = freezed,Object? automate24h = null,}) {
  return _then(_self.copyWith(
days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<DayHours>,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as OpeningHoursAvailability,rawSource: freezed == rawSource ? _self.rawSource : rawSource // ignore: cast_nullable_to_non_nullable
as String?,automate24h: null == automate24h ? _self.automate24h : automate24h // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklyOpeningHours].
extension WeeklyOpeningHoursPatterns on WeeklyOpeningHours {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyOpeningHours value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyOpeningHours() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyOpeningHours value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyOpeningHours():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyOpeningHours value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyOpeningHours() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DayHours> days,  OpeningHoursAvailability availability,  String? rawSource,  bool automate24h)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyOpeningHours() when $default != null:
return $default(_that.days,_that.availability,_that.rawSource,_that.automate24h);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DayHours> days,  OpeningHoursAvailability availability,  String? rawSource,  bool automate24h)  $default,) {final _that = this;
switch (_that) {
case _WeeklyOpeningHours():
return $default(_that.days,_that.availability,_that.rawSource,_that.automate24h);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DayHours> days,  OpeningHoursAvailability availability,  String? rawSource,  bool automate24h)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyOpeningHours() when $default != null:
return $default(_that.days,_that.availability,_that.rawSource,_that.automate24h);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklyOpeningHours extends WeeklyOpeningHours {
  const _WeeklyOpeningHours({final  List<DayHours> days = const [], this.availability = OpeningHoursAvailability.notProvided, this.rawSource, this.automate24h = false}): _days = days,super._();
  factory _WeeklyOpeningHours.fromJson(Map<String, dynamic> json) => _$WeeklyOpeningHoursFromJson(json);

 final  List<DayHours> _days;
@override@JsonKey() List<DayHours> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}

@override@JsonKey() final  OpeningHoursAvailability availability;
@override final  String? rawSource;
@override@JsonKey() final  bool automate24h;

/// Create a copy of WeeklyOpeningHours
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyOpeningHoursCopyWith<_WeeklyOpeningHours> get copyWith => __$WeeklyOpeningHoursCopyWithImpl<_WeeklyOpeningHours>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklyOpeningHoursToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyOpeningHours&&const DeepCollectionEquality().equals(other._days, _days)&&(identical(other.availability, availability) || other.availability == availability)&&(identical(other.rawSource, rawSource) || other.rawSource == rawSource)&&(identical(other.automate24h, automate24h) || other.automate24h == automate24h));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_days),availability,rawSource,automate24h);

@override
String toString() {
  return 'WeeklyOpeningHours(days: $days, availability: $availability, rawSource: $rawSource, automate24h: $automate24h)';
}


}

/// @nodoc
abstract mixin class _$WeeklyOpeningHoursCopyWith<$Res> implements $WeeklyOpeningHoursCopyWith<$Res> {
  factory _$WeeklyOpeningHoursCopyWith(_WeeklyOpeningHours value, $Res Function(_WeeklyOpeningHours) _then) = __$WeeklyOpeningHoursCopyWithImpl;
@override @useResult
$Res call({
 List<DayHours> days, OpeningHoursAvailability availability, String? rawSource, bool automate24h
});




}
/// @nodoc
class __$WeeklyOpeningHoursCopyWithImpl<$Res>
    implements _$WeeklyOpeningHoursCopyWith<$Res> {
  __$WeeklyOpeningHoursCopyWithImpl(this._self, this._then);

  final _WeeklyOpeningHours _self;
  final $Res Function(_WeeklyOpeningHours) _then;

/// Create a copy of WeeklyOpeningHours
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? days = null,Object? availability = null,Object? rawSource = freezed,Object? automate24h = null,}) {
  return _then(_WeeklyOpeningHours(
days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<DayHours>,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as OpeningHoursAvailability,rawSource: freezed == rawSource ? _self.rawSource : rawSource // ignore: cast_nullable_to_non_nullable
as String?,automate24h: null == automate24h ? _self.automate24h : automate24h // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
