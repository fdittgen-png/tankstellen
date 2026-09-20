// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_meta.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DocumentMeta {

 String get id;/// Tenancy key — the organisation the document belongs to.
 String get orgId;/// The employee who captured or imported it.
 String get ownerId; FleetDocumentType get type;/// Key in PRIVATE object storage. Never a public URL: ADR 0025
/// forbids a publicly-addressable receipt.
 String get objectKey;/// Lower-case hex SHA-256 of the stored bytes. The duplicate key.
 String get sha256;/// When the document was captured / imported — UTC, injected clock.
 DateTime get capturedAt;/// Which engine read it (`mlkit`, `none` for a structured invoice).
 String? get ocrEngine;/// That engine's version, so a re-read can be compared honestly.
 String? get ocrVersion;/// Extraction confidence in [0, 1]; null when nothing was read.
 double? get confidence; DocumentRetentionClass get retentionClass; DocumentDeletionStatus get deletionStatus;
/// Create a copy of DocumentMeta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentMetaCopyWith<DocumentMeta> get copyWith => _$DocumentMetaCopyWithImpl<DocumentMeta>(this as DocumentMeta, _$identity);

  /// Serializes this DocumentMeta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentMeta&&(identical(other.id, id) || other.id == id)&&(identical(other.orgId, orgId) || other.orgId == orgId)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.type, type) || other.type == type)&&(identical(other.objectKey, objectKey) || other.objectKey == objectKey)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt)&&(identical(other.ocrEngine, ocrEngine) || other.ocrEngine == ocrEngine)&&(identical(other.ocrVersion, ocrVersion) || other.ocrVersion == ocrVersion)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.retentionClass, retentionClass) || other.retentionClass == retentionClass)&&(identical(other.deletionStatus, deletionStatus) || other.deletionStatus == deletionStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orgId,ownerId,type,objectKey,sha256,capturedAt,ocrEngine,ocrVersion,confidence,retentionClass,deletionStatus);

@override
String toString() {
  return 'DocumentMeta(id: $id, orgId: $orgId, ownerId: $ownerId, type: $type, objectKey: $objectKey, sha256: $sha256, capturedAt: $capturedAt, ocrEngine: $ocrEngine, ocrVersion: $ocrVersion, confidence: $confidence, retentionClass: $retentionClass, deletionStatus: $deletionStatus)';
}


}

/// @nodoc
abstract mixin class $DocumentMetaCopyWith<$Res>  {
  factory $DocumentMetaCopyWith(DocumentMeta value, $Res Function(DocumentMeta) _then) = _$DocumentMetaCopyWithImpl;
@useResult
$Res call({
 String id, String orgId, String ownerId, FleetDocumentType type, String objectKey, String sha256, DateTime capturedAt, String? ocrEngine, String? ocrVersion, double? confidence, DocumentRetentionClass retentionClass, DocumentDeletionStatus deletionStatus
});




}
/// @nodoc
class _$DocumentMetaCopyWithImpl<$Res>
    implements $DocumentMetaCopyWith<$Res> {
  _$DocumentMetaCopyWithImpl(this._self, this._then);

  final DocumentMeta _self;
  final $Res Function(DocumentMeta) _then;

/// Create a copy of DocumentMeta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orgId = null,Object? ownerId = null,Object? type = null,Object? objectKey = null,Object? sha256 = null,Object? capturedAt = null,Object? ocrEngine = freezed,Object? ocrVersion = freezed,Object? confidence = freezed,Object? retentionClass = null,Object? deletionStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orgId: null == orgId ? _self.orgId : orgId // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as FleetDocumentType,objectKey: null == objectKey ? _self.objectKey : objectKey // ignore: cast_nullable_to_non_nullable
as String,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,capturedAt: null == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime,ocrEngine: freezed == ocrEngine ? _self.ocrEngine : ocrEngine // ignore: cast_nullable_to_non_nullable
as String?,ocrVersion: freezed == ocrVersion ? _self.ocrVersion : ocrVersion // ignore: cast_nullable_to_non_nullable
as String?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,retentionClass: null == retentionClass ? _self.retentionClass : retentionClass // ignore: cast_nullable_to_non_nullable
as DocumentRetentionClass,deletionStatus: null == deletionStatus ? _self.deletionStatus : deletionStatus // ignore: cast_nullable_to_non_nullable
as DocumentDeletionStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentMeta].
extension DocumentMetaPatterns on DocumentMeta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentMeta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentMeta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentMeta value)  $default,){
final _that = this;
switch (_that) {
case _DocumentMeta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentMeta value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentMeta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orgId,  String ownerId,  FleetDocumentType type,  String objectKey,  String sha256,  DateTime capturedAt,  String? ocrEngine,  String? ocrVersion,  double? confidence,  DocumentRetentionClass retentionClass,  DocumentDeletionStatus deletionStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentMeta() when $default != null:
return $default(_that.id,_that.orgId,_that.ownerId,_that.type,_that.objectKey,_that.sha256,_that.capturedAt,_that.ocrEngine,_that.ocrVersion,_that.confidence,_that.retentionClass,_that.deletionStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orgId,  String ownerId,  FleetDocumentType type,  String objectKey,  String sha256,  DateTime capturedAt,  String? ocrEngine,  String? ocrVersion,  double? confidence,  DocumentRetentionClass retentionClass,  DocumentDeletionStatus deletionStatus)  $default,) {final _that = this;
switch (_that) {
case _DocumentMeta():
return $default(_that.id,_that.orgId,_that.ownerId,_that.type,_that.objectKey,_that.sha256,_that.capturedAt,_that.ocrEngine,_that.ocrVersion,_that.confidence,_that.retentionClass,_that.deletionStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orgId,  String ownerId,  FleetDocumentType type,  String objectKey,  String sha256,  DateTime capturedAt,  String? ocrEngine,  String? ocrVersion,  double? confidence,  DocumentRetentionClass retentionClass,  DocumentDeletionStatus deletionStatus)?  $default,) {final _that = this;
switch (_that) {
case _DocumentMeta() when $default != null:
return $default(_that.id,_that.orgId,_that.ownerId,_that.type,_that.objectKey,_that.sha256,_that.capturedAt,_that.ocrEngine,_that.ocrVersion,_that.confidence,_that.retentionClass,_that.deletionStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentMeta implements DocumentMeta {
  const _DocumentMeta({required this.id, required this.orgId, required this.ownerId, required this.type, required this.objectKey, required this.sha256, required this.capturedAt, this.ocrEngine, this.ocrVersion, this.confidence, this.retentionClass = DocumentRetentionClass.userManaged, this.deletionStatus = DocumentDeletionStatus.active});
  factory _DocumentMeta.fromJson(Map<String, dynamic> json) => _$DocumentMetaFromJson(json);

@override final  String id;
/// Tenancy key — the organisation the document belongs to.
@override final  String orgId;
/// The employee who captured or imported it.
@override final  String ownerId;
@override final  FleetDocumentType type;
/// Key in PRIVATE object storage. Never a public URL: ADR 0025
/// forbids a publicly-addressable receipt.
@override final  String objectKey;
/// Lower-case hex SHA-256 of the stored bytes. The duplicate key.
@override final  String sha256;
/// When the document was captured / imported — UTC, injected clock.
@override final  DateTime capturedAt;
/// Which engine read it (`mlkit`, `none` for a structured invoice).
@override final  String? ocrEngine;
/// That engine's version, so a re-read can be compared honestly.
@override final  String? ocrVersion;
/// Extraction confidence in [0, 1]; null when nothing was read.
@override final  double? confidence;
@override@JsonKey() final  DocumentRetentionClass retentionClass;
@override@JsonKey() final  DocumentDeletionStatus deletionStatus;

/// Create a copy of DocumentMeta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentMetaCopyWith<_DocumentMeta> get copyWith => __$DocumentMetaCopyWithImpl<_DocumentMeta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentMetaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentMeta&&(identical(other.id, id) || other.id == id)&&(identical(other.orgId, orgId) || other.orgId == orgId)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.type, type) || other.type == type)&&(identical(other.objectKey, objectKey) || other.objectKey == objectKey)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt)&&(identical(other.ocrEngine, ocrEngine) || other.ocrEngine == ocrEngine)&&(identical(other.ocrVersion, ocrVersion) || other.ocrVersion == ocrVersion)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.retentionClass, retentionClass) || other.retentionClass == retentionClass)&&(identical(other.deletionStatus, deletionStatus) || other.deletionStatus == deletionStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orgId,ownerId,type,objectKey,sha256,capturedAt,ocrEngine,ocrVersion,confidence,retentionClass,deletionStatus);

@override
String toString() {
  return 'DocumentMeta(id: $id, orgId: $orgId, ownerId: $ownerId, type: $type, objectKey: $objectKey, sha256: $sha256, capturedAt: $capturedAt, ocrEngine: $ocrEngine, ocrVersion: $ocrVersion, confidence: $confidence, retentionClass: $retentionClass, deletionStatus: $deletionStatus)';
}


}

/// @nodoc
abstract mixin class _$DocumentMetaCopyWith<$Res> implements $DocumentMetaCopyWith<$Res> {
  factory _$DocumentMetaCopyWith(_DocumentMeta value, $Res Function(_DocumentMeta) _then) = __$DocumentMetaCopyWithImpl;
@override @useResult
$Res call({
 String id, String orgId, String ownerId, FleetDocumentType type, String objectKey, String sha256, DateTime capturedAt, String? ocrEngine, String? ocrVersion, double? confidence, DocumentRetentionClass retentionClass, DocumentDeletionStatus deletionStatus
});




}
/// @nodoc
class __$DocumentMetaCopyWithImpl<$Res>
    implements _$DocumentMetaCopyWith<$Res> {
  __$DocumentMetaCopyWithImpl(this._self, this._then);

  final _DocumentMeta _self;
  final $Res Function(_DocumentMeta) _then;

/// Create a copy of DocumentMeta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orgId = null,Object? ownerId = null,Object? type = null,Object? objectKey = null,Object? sha256 = null,Object? capturedAt = null,Object? ocrEngine = freezed,Object? ocrVersion = freezed,Object? confidence = freezed,Object? retentionClass = null,Object? deletionStatus = null,}) {
  return _then(_DocumentMeta(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orgId: null == orgId ? _self.orgId : orgId // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as FleetDocumentType,objectKey: null == objectKey ? _self.objectKey : objectKey // ignore: cast_nullable_to_non_nullable
as String,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,capturedAt: null == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime,ocrEngine: freezed == ocrEngine ? _self.ocrEngine : ocrEngine // ignore: cast_nullable_to_non_nullable
as String?,ocrVersion: freezed == ocrVersion ? _self.ocrVersion : ocrVersion // ignore: cast_nullable_to_non_nullable
as String?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,retentionClass: null == retentionClass ? _self.retentionClass : retentionClass // ignore: cast_nullable_to_non_nullable
as DocumentRetentionClass,deletionStatus: null == deletionStatus ? _self.deletionStatus : deletionStatus // ignore: cast_nullable_to_non_nullable
as DocumentDeletionStatus,
  ));
}


}

// dart format on
