// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExpenseTransition {

 ExpenseStatus get from; ExpenseStatus get to;/// UTC, from the injected `AppClock`.
 DateTime get at;/// The user who caused the move.
 String get byUserId;/// Free-form machine-readable reason (a rejection code, say).
/// Never user-facing text — the UI renders its own from ARB.
 String? get reason;
/// Create a copy of ExpenseTransition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseTransitionCopyWith<ExpenseTransition> get copyWith => _$ExpenseTransitionCopyWithImpl<ExpenseTransition>(this as ExpenseTransition, _$identity);

  /// Serializes this ExpenseTransition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseTransition&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.at, at) || other.at == at)&&(identical(other.byUserId, byUserId) || other.byUserId == byUserId)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,at,byUserId,reason);

@override
String toString() {
  return 'ExpenseTransition(from: $from, to: $to, at: $at, byUserId: $byUserId, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $ExpenseTransitionCopyWith<$Res>  {
  factory $ExpenseTransitionCopyWith(ExpenseTransition value, $Res Function(ExpenseTransition) _then) = _$ExpenseTransitionCopyWithImpl;
@useResult
$Res call({
 ExpenseStatus from, ExpenseStatus to, DateTime at, String byUserId, String? reason
});




}
/// @nodoc
class _$ExpenseTransitionCopyWithImpl<$Res>
    implements $ExpenseTransitionCopyWith<$Res> {
  _$ExpenseTransitionCopyWithImpl(this._self, this._then);

  final ExpenseTransition _self;
  final $Res Function(ExpenseTransition) _then;

/// Create a copy of ExpenseTransition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? to = null,Object? at = null,Object? byUserId = null,Object? reason = freezed,}) {
  return _then(_self.copyWith(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as ExpenseStatus,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as ExpenseStatus,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,byUserId: null == byUserId ? _self.byUserId : byUserId // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpenseTransition].
extension ExpenseTransitionPatterns on ExpenseTransition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpenseTransition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpenseTransition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpenseTransition value)  $default,){
final _that = this;
switch (_that) {
case _ExpenseTransition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpenseTransition value)?  $default,){
final _that = this;
switch (_that) {
case _ExpenseTransition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ExpenseStatus from,  ExpenseStatus to,  DateTime at,  String byUserId,  String? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpenseTransition() when $default != null:
return $default(_that.from,_that.to,_that.at,_that.byUserId,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ExpenseStatus from,  ExpenseStatus to,  DateTime at,  String byUserId,  String? reason)  $default,) {final _that = this;
switch (_that) {
case _ExpenseTransition():
return $default(_that.from,_that.to,_that.at,_that.byUserId,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ExpenseStatus from,  ExpenseStatus to,  DateTime at,  String byUserId,  String? reason)?  $default,) {final _that = this;
switch (_that) {
case _ExpenseTransition() when $default != null:
return $default(_that.from,_that.to,_that.at,_that.byUserId,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExpenseTransition implements ExpenseTransition {
  const _ExpenseTransition({required this.from, required this.to, required this.at, required this.byUserId, this.reason});
  factory _ExpenseTransition.fromJson(Map<String, dynamic> json) => _$ExpenseTransitionFromJson(json);

@override final  ExpenseStatus from;
@override final  ExpenseStatus to;
/// UTC, from the injected `AppClock`.
@override final  DateTime at;
/// The user who caused the move.
@override final  String byUserId;
/// Free-form machine-readable reason (a rejection code, say).
/// Never user-facing text — the UI renders its own from ARB.
@override final  String? reason;

/// Create a copy of ExpenseTransition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseTransitionCopyWith<_ExpenseTransition> get copyWith => __$ExpenseTransitionCopyWithImpl<_ExpenseTransition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseTransitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpenseTransition&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.at, at) || other.at == at)&&(identical(other.byUserId, byUserId) || other.byUserId == byUserId)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,at,byUserId,reason);

@override
String toString() {
  return 'ExpenseTransition(from: $from, to: $to, at: $at, byUserId: $byUserId, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$ExpenseTransitionCopyWith<$Res> implements $ExpenseTransitionCopyWith<$Res> {
  factory _$ExpenseTransitionCopyWith(_ExpenseTransition value, $Res Function(_ExpenseTransition) _then) = __$ExpenseTransitionCopyWithImpl;
@override @useResult
$Res call({
 ExpenseStatus from, ExpenseStatus to, DateTime at, String byUserId, String? reason
});




}
/// @nodoc
class __$ExpenseTransitionCopyWithImpl<$Res>
    implements _$ExpenseTransitionCopyWith<$Res> {
  __$ExpenseTransitionCopyWithImpl(this._self, this._then);

  final _ExpenseTransition _self;
  final $Res Function(_ExpenseTransition) _then;

/// Create a copy of ExpenseTransition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,Object? at = null,Object? byUserId = null,Object? reason = freezed,}) {
  return _then(_ExpenseTransition(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as ExpenseStatus,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as ExpenseStatus,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,byUserId: null == byUserId ? _self.byUserId : byUserId // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$FleetAttribution {

 String get orgId; String get fleetVehicleId;/// The `vehicle_assignments` row that justified it, when one did.
 String? get assignmentId;/// When the attribution was decided — UTC, injected clock.
 DateTime get capturedAt;
/// Create a copy of FleetAttribution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FleetAttributionCopyWith<FleetAttribution> get copyWith => _$FleetAttributionCopyWithImpl<FleetAttribution>(this as FleetAttribution, _$identity);

  /// Serializes this FleetAttribution to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FleetAttribution&&(identical(other.orgId, orgId) || other.orgId == orgId)&&(identical(other.fleetVehicleId, fleetVehicleId) || other.fleetVehicleId == fleetVehicleId)&&(identical(other.assignmentId, assignmentId) || other.assignmentId == assignmentId)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orgId,fleetVehicleId,assignmentId,capturedAt);

@override
String toString() {
  return 'FleetAttribution(orgId: $orgId, fleetVehicleId: $fleetVehicleId, assignmentId: $assignmentId, capturedAt: $capturedAt)';
}


}

/// @nodoc
abstract mixin class $FleetAttributionCopyWith<$Res>  {
  factory $FleetAttributionCopyWith(FleetAttribution value, $Res Function(FleetAttribution) _then) = _$FleetAttributionCopyWithImpl;
@useResult
$Res call({
 String orgId, String fleetVehicleId, String? assignmentId, DateTime capturedAt
});




}
/// @nodoc
class _$FleetAttributionCopyWithImpl<$Res>
    implements $FleetAttributionCopyWith<$Res> {
  _$FleetAttributionCopyWithImpl(this._self, this._then);

  final FleetAttribution _self;
  final $Res Function(FleetAttribution) _then;

/// Create a copy of FleetAttribution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orgId = null,Object? fleetVehicleId = null,Object? assignmentId = freezed,Object? capturedAt = null,}) {
  return _then(_self.copyWith(
orgId: null == orgId ? _self.orgId : orgId // ignore: cast_nullable_to_non_nullable
as String,fleetVehicleId: null == fleetVehicleId ? _self.fleetVehicleId : fleetVehicleId // ignore: cast_nullable_to_non_nullable
as String,assignmentId: freezed == assignmentId ? _self.assignmentId : assignmentId // ignore: cast_nullable_to_non_nullable
as String?,capturedAt: null == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [FleetAttribution].
extension FleetAttributionPatterns on FleetAttribution {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FleetAttribution value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FleetAttribution() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FleetAttribution value)  $default,){
final _that = this;
switch (_that) {
case _FleetAttribution():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FleetAttribution value)?  $default,){
final _that = this;
switch (_that) {
case _FleetAttribution() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String orgId,  String fleetVehicleId,  String? assignmentId,  DateTime capturedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FleetAttribution() when $default != null:
return $default(_that.orgId,_that.fleetVehicleId,_that.assignmentId,_that.capturedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String orgId,  String fleetVehicleId,  String? assignmentId,  DateTime capturedAt)  $default,) {final _that = this;
switch (_that) {
case _FleetAttribution():
return $default(_that.orgId,_that.fleetVehicleId,_that.assignmentId,_that.capturedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String orgId,  String fleetVehicleId,  String? assignmentId,  DateTime capturedAt)?  $default,) {final _that = this;
switch (_that) {
case _FleetAttribution() when $default != null:
return $default(_that.orgId,_that.fleetVehicleId,_that.assignmentId,_that.capturedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FleetAttribution implements FleetAttribution {
  const _FleetAttribution({required this.orgId, required this.fleetVehicleId, this.assignmentId, required this.capturedAt});
  factory _FleetAttribution.fromJson(Map<String, dynamic> json) => _$FleetAttributionFromJson(json);

@override final  String orgId;
@override final  String fleetVehicleId;
/// The `vehicle_assignments` row that justified it, when one did.
@override final  String? assignmentId;
/// When the attribution was decided — UTC, injected clock.
@override final  DateTime capturedAt;

/// Create a copy of FleetAttribution
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FleetAttributionCopyWith<_FleetAttribution> get copyWith => __$FleetAttributionCopyWithImpl<_FleetAttribution>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FleetAttributionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FleetAttribution&&(identical(other.orgId, orgId) || other.orgId == orgId)&&(identical(other.fleetVehicleId, fleetVehicleId) || other.fleetVehicleId == fleetVehicleId)&&(identical(other.assignmentId, assignmentId) || other.assignmentId == assignmentId)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orgId,fleetVehicleId,assignmentId,capturedAt);

@override
String toString() {
  return 'FleetAttribution(orgId: $orgId, fleetVehicleId: $fleetVehicleId, assignmentId: $assignmentId, capturedAt: $capturedAt)';
}


}

/// @nodoc
abstract mixin class _$FleetAttributionCopyWith<$Res> implements $FleetAttributionCopyWith<$Res> {
  factory _$FleetAttributionCopyWith(_FleetAttribution value, $Res Function(_FleetAttribution) _then) = __$FleetAttributionCopyWithImpl;
@override @useResult
$Res call({
 String orgId, String fleetVehicleId, String? assignmentId, DateTime capturedAt
});




}
/// @nodoc
class __$FleetAttributionCopyWithImpl<$Res>
    implements _$FleetAttributionCopyWith<$Res> {
  __$FleetAttributionCopyWithImpl(this._self, this._then);

  final _FleetAttribution _self;
  final $Res Function(_FleetAttribution) _then;

/// Create a copy of FleetAttribution
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orgId = null,Object? fleetVehicleId = null,Object? assignmentId = freezed,Object? capturedAt = null,}) {
  return _then(_FleetAttribution(
orgId: null == orgId ? _self.orgId : orgId // ignore: cast_nullable_to_non_nullable
as String,fleetVehicleId: null == fleetVehicleId ? _self.fleetVehicleId : fleetVehicleId // ignore: cast_nullable_to_non_nullable
as String,assignmentId: freezed == assignmentId ? _self.assignmentId : assignmentId // ignore: cast_nullable_to_non_nullable
as String?,capturedAt: null == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$Expense {

 String get id;/// The organisation the expense belongs to — the tenancy key.
 String get orgId;/// The employee who submitted it.
 String get userId;/// The fill-up this expense is the receipt FOR, when one matched.
/// Set by the reconciler's attach path; an expense never creates a
/// second fill-up for a purchase the user already logged.
 String? get fillUpId;/// The company vehicle, frozen at capture time.
 FleetAttribution? get fleetAttribution;/// What the machine read. Immutable for the life of the expense.
 ExtractedReceiptFields get extracted;/// What the employee stands behind. Starts equal to [extracted].
 ExtractedReceiptFields get confirmed;/// Every difference between [extracted] and [confirmed], in order.
 List<FieldCorrection> get corrections;/// The `fleet_documents` row holding the source document. Null for
/// an expense typed by hand.
 String? get documentId;/// How the document arrived.
 ExpenseImportSource get importSource;/// `true` only for a document the deployment treats as an
/// authoritative record (a received e-invoice). A scan is never
/// authoritative, whatever its confidence.
 bool get authoritative;/// Where it stands. A scan can only produce [ExpenseStatus.draft]
/// or [ExpenseStatus.needsReview].
 ExpenseStatus get status;/// Every state move, with who and when.
 List<ExpenseTransition> get history;/// Claim class 4 — fixed. Present as a field so a persisted row
/// states it rather than leaving a reader to assume it.
 ClaimClass get claim;
/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseCopyWith<Expense> get copyWith => _$ExpenseCopyWithImpl<Expense>(this as Expense, _$identity);

  /// Serializes this Expense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Expense&&(identical(other.id, id) || other.id == id)&&(identical(other.orgId, orgId) || other.orgId == orgId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fillUpId, fillUpId) || other.fillUpId == fillUpId)&&(identical(other.fleetAttribution, fleetAttribution) || other.fleetAttribution == fleetAttribution)&&(identical(other.extracted, extracted) || other.extracted == extracted)&&(identical(other.confirmed, confirmed) || other.confirmed == confirmed)&&const DeepCollectionEquality().equals(other.corrections, corrections)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.importSource, importSource) || other.importSource == importSource)&&(identical(other.authoritative, authoritative) || other.authoritative == authoritative)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.history, history)&&(identical(other.claim, claim) || other.claim == claim));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orgId,userId,fillUpId,fleetAttribution,extracted,confirmed,const DeepCollectionEquality().hash(corrections),documentId,importSource,authoritative,status,const DeepCollectionEquality().hash(history),claim);

@override
String toString() {
  return 'Expense(id: $id, orgId: $orgId, userId: $userId, fillUpId: $fillUpId, fleetAttribution: $fleetAttribution, extracted: $extracted, confirmed: $confirmed, corrections: $corrections, documentId: $documentId, importSource: $importSource, authoritative: $authoritative, status: $status, history: $history, claim: $claim)';
}


}

/// @nodoc
abstract mixin class $ExpenseCopyWith<$Res>  {
  factory $ExpenseCopyWith(Expense value, $Res Function(Expense) _then) = _$ExpenseCopyWithImpl;
@useResult
$Res call({
 String id, String orgId, String userId, String? fillUpId, FleetAttribution? fleetAttribution, ExtractedReceiptFields extracted, ExtractedReceiptFields confirmed, List<FieldCorrection> corrections, String? documentId, ExpenseImportSource importSource, bool authoritative, ExpenseStatus status, List<ExpenseTransition> history, ClaimClass claim
});


$FleetAttributionCopyWith<$Res>? get fleetAttribution;$ExtractedReceiptFieldsCopyWith<$Res> get extracted;$ExtractedReceiptFieldsCopyWith<$Res> get confirmed;

}
/// @nodoc
class _$ExpenseCopyWithImpl<$Res>
    implements $ExpenseCopyWith<$Res> {
  _$ExpenseCopyWithImpl(this._self, this._then);

  final Expense _self;
  final $Res Function(Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orgId = null,Object? userId = null,Object? fillUpId = freezed,Object? fleetAttribution = freezed,Object? extracted = null,Object? confirmed = null,Object? corrections = null,Object? documentId = freezed,Object? importSource = null,Object? authoritative = null,Object? status = null,Object? history = null,Object? claim = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orgId: null == orgId ? _self.orgId : orgId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fillUpId: freezed == fillUpId ? _self.fillUpId : fillUpId // ignore: cast_nullable_to_non_nullable
as String?,fleetAttribution: freezed == fleetAttribution ? _self.fleetAttribution : fleetAttribution // ignore: cast_nullable_to_non_nullable
as FleetAttribution?,extracted: null == extracted ? _self.extracted : extracted // ignore: cast_nullable_to_non_nullable
as ExtractedReceiptFields,confirmed: null == confirmed ? _self.confirmed : confirmed // ignore: cast_nullable_to_non_nullable
as ExtractedReceiptFields,corrections: null == corrections ? _self.corrections : corrections // ignore: cast_nullable_to_non_nullable
as List<FieldCorrection>,documentId: freezed == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String?,importSource: null == importSource ? _self.importSource : importSource // ignore: cast_nullable_to_non_nullable
as ExpenseImportSource,authoritative: null == authoritative ? _self.authoritative : authoritative // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ExpenseStatus,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<ExpenseTransition>,claim: null == claim ? _self.claim : claim // ignore: cast_nullable_to_non_nullable
as ClaimClass,
  ));
}
/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FleetAttributionCopyWith<$Res>? get fleetAttribution {
    if (_self.fleetAttribution == null) {
    return null;
  }

  return $FleetAttributionCopyWith<$Res>(_self.fleetAttribution!, (value) {
    return _then(_self.copyWith(fleetAttribution: value));
  });
}/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExtractedReceiptFieldsCopyWith<$Res> get extracted {
  
  return $ExtractedReceiptFieldsCopyWith<$Res>(_self.extracted, (value) {
    return _then(_self.copyWith(extracted: value));
  });
}/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExtractedReceiptFieldsCopyWith<$Res> get confirmed {
  
  return $ExtractedReceiptFieldsCopyWith<$Res>(_self.confirmed, (value) {
    return _then(_self.copyWith(confirmed: value));
  });
}
}


/// Adds pattern-matching-related methods to [Expense].
extension ExpensePatterns on Expense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Expense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Expense value)  $default,){
final _that = this;
switch (_that) {
case _Expense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Expense value)?  $default,){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orgId,  String userId,  String? fillUpId,  FleetAttribution? fleetAttribution,  ExtractedReceiptFields extracted,  ExtractedReceiptFields confirmed,  List<FieldCorrection> corrections,  String? documentId,  ExpenseImportSource importSource,  bool authoritative,  ExpenseStatus status,  List<ExpenseTransition> history,  ClaimClass claim)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.id,_that.orgId,_that.userId,_that.fillUpId,_that.fleetAttribution,_that.extracted,_that.confirmed,_that.corrections,_that.documentId,_that.importSource,_that.authoritative,_that.status,_that.history,_that.claim);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orgId,  String userId,  String? fillUpId,  FleetAttribution? fleetAttribution,  ExtractedReceiptFields extracted,  ExtractedReceiptFields confirmed,  List<FieldCorrection> corrections,  String? documentId,  ExpenseImportSource importSource,  bool authoritative,  ExpenseStatus status,  List<ExpenseTransition> history,  ClaimClass claim)  $default,) {final _that = this;
switch (_that) {
case _Expense():
return $default(_that.id,_that.orgId,_that.userId,_that.fillUpId,_that.fleetAttribution,_that.extracted,_that.confirmed,_that.corrections,_that.documentId,_that.importSource,_that.authoritative,_that.status,_that.history,_that.claim);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orgId,  String userId,  String? fillUpId,  FleetAttribution? fleetAttribution,  ExtractedReceiptFields extracted,  ExtractedReceiptFields confirmed,  List<FieldCorrection> corrections,  String? documentId,  ExpenseImportSource importSource,  bool authoritative,  ExpenseStatus status,  List<ExpenseTransition> history,  ClaimClass claim)?  $default,) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.id,_that.orgId,_that.userId,_that.fillUpId,_that.fleetAttribution,_that.extracted,_that.confirmed,_that.corrections,_that.documentId,_that.importSource,_that.authoritative,_that.status,_that.history,_that.claim);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Expense implements Expense {
  const _Expense({required this.id, required this.orgId, required this.userId, this.fillUpId, this.fleetAttribution, required this.extracted, required this.confirmed, final  List<FieldCorrection> corrections = const <FieldCorrection>[], this.documentId, required this.importSource, this.authoritative = false, this.status = ExpenseStatus.draft, final  List<ExpenseTransition> history = const <ExpenseTransition>[], this.claim = ClaimClass.accountingCandidate}): _corrections = corrections,_history = history;
  factory _Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);

@override final  String id;
/// The organisation the expense belongs to — the tenancy key.
@override final  String orgId;
/// The employee who submitted it.
@override final  String userId;
/// The fill-up this expense is the receipt FOR, when one matched.
/// Set by the reconciler's attach path; an expense never creates a
/// second fill-up for a purchase the user already logged.
@override final  String? fillUpId;
/// The company vehicle, frozen at capture time.
@override final  FleetAttribution? fleetAttribution;
/// What the machine read. Immutable for the life of the expense.
@override final  ExtractedReceiptFields extracted;
/// What the employee stands behind. Starts equal to [extracted].
@override final  ExtractedReceiptFields confirmed;
/// Every difference between [extracted] and [confirmed], in order.
 final  List<FieldCorrection> _corrections;
/// Every difference between [extracted] and [confirmed], in order.
@override@JsonKey() List<FieldCorrection> get corrections {
  if (_corrections is EqualUnmodifiableListView) return _corrections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_corrections);
}

/// The `fleet_documents` row holding the source document. Null for
/// an expense typed by hand.
@override final  String? documentId;
/// How the document arrived.
@override final  ExpenseImportSource importSource;
/// `true` only for a document the deployment treats as an
/// authoritative record (a received e-invoice). A scan is never
/// authoritative, whatever its confidence.
@override@JsonKey() final  bool authoritative;
/// Where it stands. A scan can only produce [ExpenseStatus.draft]
/// or [ExpenseStatus.needsReview].
@override@JsonKey() final  ExpenseStatus status;
/// Every state move, with who and when.
 final  List<ExpenseTransition> _history;
/// Every state move, with who and when.
@override@JsonKey() List<ExpenseTransition> get history {
  if (_history is EqualUnmodifiableListView) return _history;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_history);
}

/// Claim class 4 — fixed. Present as a field so a persisted row
/// states it rather than leaving a reader to assume it.
@override@JsonKey() final  ClaimClass claim;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseCopyWith<_Expense> get copyWith => __$ExpenseCopyWithImpl<_Expense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Expense&&(identical(other.id, id) || other.id == id)&&(identical(other.orgId, orgId) || other.orgId == orgId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fillUpId, fillUpId) || other.fillUpId == fillUpId)&&(identical(other.fleetAttribution, fleetAttribution) || other.fleetAttribution == fleetAttribution)&&(identical(other.extracted, extracted) || other.extracted == extracted)&&(identical(other.confirmed, confirmed) || other.confirmed == confirmed)&&const DeepCollectionEquality().equals(other._corrections, _corrections)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.importSource, importSource) || other.importSource == importSource)&&(identical(other.authoritative, authoritative) || other.authoritative == authoritative)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._history, _history)&&(identical(other.claim, claim) || other.claim == claim));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orgId,userId,fillUpId,fleetAttribution,extracted,confirmed,const DeepCollectionEquality().hash(_corrections),documentId,importSource,authoritative,status,const DeepCollectionEquality().hash(_history),claim);

@override
String toString() {
  return 'Expense(id: $id, orgId: $orgId, userId: $userId, fillUpId: $fillUpId, fleetAttribution: $fleetAttribution, extracted: $extracted, confirmed: $confirmed, corrections: $corrections, documentId: $documentId, importSource: $importSource, authoritative: $authoritative, status: $status, history: $history, claim: $claim)';
}


}

/// @nodoc
abstract mixin class _$ExpenseCopyWith<$Res> implements $ExpenseCopyWith<$Res> {
  factory _$ExpenseCopyWith(_Expense value, $Res Function(_Expense) _then) = __$ExpenseCopyWithImpl;
@override @useResult
$Res call({
 String id, String orgId, String userId, String? fillUpId, FleetAttribution? fleetAttribution, ExtractedReceiptFields extracted, ExtractedReceiptFields confirmed, List<FieldCorrection> corrections, String? documentId, ExpenseImportSource importSource, bool authoritative, ExpenseStatus status, List<ExpenseTransition> history, ClaimClass claim
});


@override $FleetAttributionCopyWith<$Res>? get fleetAttribution;@override $ExtractedReceiptFieldsCopyWith<$Res> get extracted;@override $ExtractedReceiptFieldsCopyWith<$Res> get confirmed;

}
/// @nodoc
class __$ExpenseCopyWithImpl<$Res>
    implements _$ExpenseCopyWith<$Res> {
  __$ExpenseCopyWithImpl(this._self, this._then);

  final _Expense _self;
  final $Res Function(_Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orgId = null,Object? userId = null,Object? fillUpId = freezed,Object? fleetAttribution = freezed,Object? extracted = null,Object? confirmed = null,Object? corrections = null,Object? documentId = freezed,Object? importSource = null,Object? authoritative = null,Object? status = null,Object? history = null,Object? claim = null,}) {
  return _then(_Expense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orgId: null == orgId ? _self.orgId : orgId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fillUpId: freezed == fillUpId ? _self.fillUpId : fillUpId // ignore: cast_nullable_to_non_nullable
as String?,fleetAttribution: freezed == fleetAttribution ? _self.fleetAttribution : fleetAttribution // ignore: cast_nullable_to_non_nullable
as FleetAttribution?,extracted: null == extracted ? _self.extracted : extracted // ignore: cast_nullable_to_non_nullable
as ExtractedReceiptFields,confirmed: null == confirmed ? _self.confirmed : confirmed // ignore: cast_nullable_to_non_nullable
as ExtractedReceiptFields,corrections: null == corrections ? _self._corrections : corrections // ignore: cast_nullable_to_non_nullable
as List<FieldCorrection>,documentId: freezed == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String?,importSource: null == importSource ? _self.importSource : importSource // ignore: cast_nullable_to_non_nullable
as ExpenseImportSource,authoritative: null == authoritative ? _self.authoritative : authoritative // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ExpenseStatus,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<ExpenseTransition>,claim: null == claim ? _self.claim : claim // ignore: cast_nullable_to_non_nullable
as ClaimClass,
  ));
}

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FleetAttributionCopyWith<$Res>? get fleetAttribution {
    if (_self.fleetAttribution == null) {
    return null;
  }

  return $FleetAttributionCopyWith<$Res>(_self.fleetAttribution!, (value) {
    return _then(_self.copyWith(fleetAttribution: value));
  });
}/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExtractedReceiptFieldsCopyWith<$Res> get extracted {
  
  return $ExtractedReceiptFieldsCopyWith<$Res>(_self.extracted, (value) {
    return _then(_self.copyWith(extracted: value));
  });
}/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExtractedReceiptFieldsCopyWith<$Res> get confirmed {
  
  return $ExtractedReceiptFieldsCopyWith<$Res>(_self.confirmed, (value) {
    return _then(_self.copyWith(confirmed: value));
  });
}
}

// dart format on
