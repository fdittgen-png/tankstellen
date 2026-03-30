import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/search_params.dart';

part 'search_mode_provider.g.dart';

@riverpod
class ActiveSearchMode extends _$ActiveSearchMode {
  @override
  SearchMode build() => SearchMode.nearby;

  void set(SearchMode mode) => state = mode;
}
