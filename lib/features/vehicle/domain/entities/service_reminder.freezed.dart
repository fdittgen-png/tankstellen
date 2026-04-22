// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_reminder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServiceReminder {

 String get id;/// The vehicle this reminder belongs to. Fills-ups are checked
/// only against reminders that match the fill-up's vehicleId.
 String get vehicleId;/// Short label — "Oil change", "Tires", "Inspection". Stored
/// verbatim; localisation happens in the UI if the label matches
/// a known preset.
 String get label;/// Service interval in km between occurrences.
 double get intervalKm;/// Odometer reading at the last service. Null when the user
/// added the reminder but hasn't yet recorded a completion — the
/// first fill-up that brings the odometer above `intervalKm`
/// will trip the alert.
 double? get lastServiceOdometerKm;/// Toggle for pausing a reminder without deleting it — the
/// trigger skips inactive reminders. Defaults to `true` so a new
/// reminder is armed immediately.
 bool get isActive;/// Set to `true` after the trigger fires and the notification
/// has been shown; reset by `markDone`. The vehicle edit row
/// shows a badge when this is `true` so the user can confirm
/// completion.
 bool get pendingAcknowledgment;
/// Create a copy of ServiceReminder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceReminderCopyWith<ServiceReminder> get copyWith => _$ServiceReminderCopyWithImpl<ServiceReminder>(this as ServiceReminder, _$identity);

  /// Serializes this ServiceReminder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceReminder&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.label, label) || other.label == label)&&(identical(other.intervalKm, intervalKm) || other.intervalKm == intervalKm)&&(identical(other.lastServiceOdometerKm, lastServiceOdometerKm) || other.lastServiceOdometerKm == lastServiceOdometerKm)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.pendingAcknowledgment, pendingAcknowledgment) || other.pendingAcknowledgment == pendingAcknowledgment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,label,intervalKm,lastServiceOdometerKm,isActive,pendingAcknowledgment);

@override
String toString() {
  return 'ServiceReminder(id: $id, vehicleId: $vehicleId, label: $label, intervalKm: $intervalKm, lastServiceOdometerKm: $lastServiceOdometerKm, isActive: $isActive, pendingAcknowledgment: $pendingAcknowledgment)';
}


}

/// @nodoc
abstract mixin class $ServiceReminderCopyWith<$Res>  {
  factory $ServiceReminderCopyWith(ServiceReminder value, $Res Function(ServiceReminder) _then) = _$ServiceReminderCopyWithImpl;
@useResult
$Res call({
 String id, String vehicleId, String label, double intervalKm, double? lastServiceOdometerKm, bool isActive, bool pendingAcknowledgment
});




}
/// @nodoc
class _$ServiceReminderCopyWithImpl<$Res>
    implements $ServiceReminderCopyWith<$Res> {
  _$ServiceReminderCopyWithImpl(this._self, this._then);

  final ServiceReminder _self;
  final $Res Function(ServiceReminder) _then;

/// Create a copy of ServiceReminder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vehicleId = null,Object? label = null,Object? intervalKm = null,Object? lastServiceOdometerKm = freezed,Object? isActive = null,Object? pendingAcknowledgment = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,intervalKm: null == intervalKm ? _self.intervalKm : intervalKm // ignore: cast_nullable_to_non_nullable
as double,lastServiceOdometerKm: freezed == lastServiceOdometerKm ? _self.lastServiceOdometerKm : lastServiceOdometerKm // ignore: cast_nullable_to_non_nullable
as double?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,pendingAcknowledgment: null == pendingAcknowledgment ? _self.pendingAcknowledgment : pendingAcknowledgment // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceReminder].
extension ServiceReminderPatterns on ServiceReminder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceReminder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceReminder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceReminder value)  $default,){
final _that = this;
switch (_that) {
case _ServiceReminder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceReminder value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceReminder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String vehicleId,  String label,  double intervalKm,  double? lastServiceOdometerKm,  bool isActive,  bool pendingAcknowledgment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceReminder() when $default != null:
return $default(_that.id,_that.vehicleId,_that.label,_that.intervalKm,_that.lastServiceOdometerKm,_that.isActive,_that.pendingAcknowledgment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String vehicleId,  String label,  double intervalKm,  double? lastServiceOdometerKm,  bool isActive,  bool pendingAcknowledgment)  $default,) {final _that = this;
switch (_that) {
case _ServiceReminder():
return $default(_that.id,_that.vehicleId,_that.label,_that.intervalKm,_that.lastServiceOdometerKm,_that.isActive,_that.pendingAcknowledgment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String vehicleId,  String label,  double intervalKm,  double? lastServiceOdometerKm,  bool isActive,  bool pendingAcknowledgment)?  $default,) {final _that = this;
switch (_that) {
case _ServiceReminder() when $default != null:
return $default(_that.id,_that.vehicleId,_that.label,_that.intervalKm,_that.lastServiceOdometerKm,_that.isActive,_that.pendingAcknowledgment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceReminder extends ServiceReminder {
  const _ServiceReminder({required this.id, required this.vehicleId, required this.label, required this.intervalKm, this.lastServiceOdometerKm, this.isActive = true, this.pendingAcknowledgment = false}): super._();
  factory _ServiceReminder.fromJson(Map<String, dynamic> json) => _$ServiceReminderFromJson(json);

@override final  String id;
/// The vehicle this reminder belongs to. Fills-ups are checked
/// only against reminders that match the fill-up's vehicleId.
@override final  String vehicleId;
/// Short label — "Oil change", "Tires", "Inspection". Stored
/// verbatim; localisation happens in the UI if the label matches
/// a known preset.
@override final  String label;
/// Service interval in km between occurrences.
@override final  double intervalKm;
/// Odometer reading at the last service. Null when the user
/// added the reminder but hasn't yet recorded a completion — the
/// first fill-up that brings the odometer above `intervalKm`
/// will trip the alert.
@override final  double? lastServiceOdometerKm;
/// Toggle for pausing a reminder without deleting it — the
/// trigger skips inactive reminders. Defaults to `true` so a new
/// reminder is armed immediately.
@override@JsonKey() final  bool isActive;
/// Set to `true` after the trigger fires and the notification
/// has been shown; reset by `markDone`. The vehicle edit row
/// shows a badge when this is `true` so the user can confirm
/// completion.
@override@JsonKey() final  bool pendingAcknowledgment;

/// Create a copy of ServiceReminder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceReminderCopyWith<_ServiceReminder> get copyWith => __$ServiceReminderCopyWithImpl<_ServiceReminder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceReminderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceReminder&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.label, label) || other.label == label)&&(identical(other.intervalKm, intervalKm) || other.intervalKm == intervalKm)&&(identical(other.lastServiceOdometerKm, lastServiceOdometerKm) || other.lastServiceOdometerKm == lastServiceOdometerKm)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.pendingAcknowledgment, pendingAcknowledgment) || other.pendingAcknowledgment == pendingAcknowledgment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,label,intervalKm,lastServiceOdometerKm,isActive,pendingAcknowledgment);

@override
String toString() {
  return 'ServiceReminder(id: $id, vehicleId: $vehicleId, label: $label, intervalKm: $intervalKm, lastServiceOdometerKm: $lastServiceOdometerKm, isActive: $isActive, pendingAcknowledgment: $pendingAcknowledgment)';
}


}

/// @nodoc
abstract mixin class _$ServiceReminderCopyWith<$Res> implements $ServiceReminderCopyWith<$Res> {
  factory _$ServiceReminderCopyWith(_ServiceReminder value, $Res Function(_ServiceReminder) _then) = __$ServiceReminderCopyWithImpl;
@override @useResult
$Res call({
 String id, String vehicleId, String label, double intervalKm, double? lastServiceOdometerKm, bool isActive, bool pendingAcknowledgment
});




}
/// @nodoc
class __$ServiceReminderCopyWithImpl<$Res>
    implements _$ServiceReminderCopyWith<$Res> {
  __$ServiceReminderCopyWithImpl(this._self, this._then);

  final _ServiceReminder _self;
  final $Res Function(_ServiceReminder) _then;

/// Create a copy of ServiceReminder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vehicleId = null,Object? label = null,Object? intervalKm = null,Object? lastServiceOdometerKm = freezed,Object? isActive = null,Object? pendingAcknowledgment = null,}) {
  return _then(_ServiceReminder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,intervalKm: null == intervalKm ? _self.intervalKm : intervalKm // ignore: cast_nullable_to_non_nullable
as double,lastServiceOdometerKm: freezed == lastServiceOdometerKm ? _self.lastServiceOdometerKm : lastServiceOdometerKm // ignore: cast_nullable_to_non_nullable
as double?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,pendingAcknowledgment: null == pendingAcknowledgment ? _self.pendingAcknowledgment : pendingAcknowledgment // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
