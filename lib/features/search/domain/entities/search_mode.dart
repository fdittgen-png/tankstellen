/// What kind of search the user is performing — the presentation layer's
/// domain model for the search tab strip. Kept in `domain/` so it can be
/// used by providers and screens without leaking imports from `data/`.
enum SearchMode {
  nearby('nearby', 'Around me'),
  route('route', 'Along route');

  final String apiValue;
  final String displayName;
  const SearchMode(this.apiValue, this.displayName);
}
