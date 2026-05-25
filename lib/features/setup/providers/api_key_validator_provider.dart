// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/api_key_validator.dart';

part 'api_key_validator_provider.g.dart';

@riverpod
ApiKeyValidator apiKeyValidator(Ref ref) {
  return ApiKeyValidator();
}
