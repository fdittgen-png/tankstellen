// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/search_mode.dart';

part 'search_mode_provider.g.dart';

@riverpod
class ActiveSearchMode extends _$ActiveSearchMode {
  @override
  SearchMode build() => SearchMode.nearby;

  void set(SearchMode mode) => state = mode;
}
