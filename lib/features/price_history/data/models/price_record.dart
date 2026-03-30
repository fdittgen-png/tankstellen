import 'package:freezed_annotation/freezed_annotation.dart';

part 'price_record.freezed.dart';
part 'price_record.g.dart';

@freezed
abstract class PriceRecord with _$PriceRecord {
  const factory PriceRecord({
    required String stationId,
    required DateTime recordedAt,
    double? e5,
    double? e10,
    double? e98,
    double? diesel,
    double? dieselPremium,
    double? e85,
    double? lpg,
    double? cng,
  }) = _PriceRecord;

  factory PriceRecord.fromJson(Map<String, dynamic> json) =>
      _$PriceRecordFromJson(json);
}
