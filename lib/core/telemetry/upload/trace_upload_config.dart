import 'package:freezed_annotation/freezed_annotation.dart';

part 'trace_upload_config.freezed.dart';
part 'trace_upload_config.g.dart';

@freezed
abstract class TraceUploadConfig with _$TraceUploadConfig {
  const factory TraceUploadConfig({
    @Default(false) bool enabled,
    String? serverUrl,
    String? authToken,
  }) = _TraceUploadConfig;

  factory TraceUploadConfig.fromJson(Map<String, dynamic> json) =>
      _$TraceUploadConfigFromJson(json);

  static const TraceUploadConfig disabled = TraceUploadConfig();
}
