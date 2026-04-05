/// Validator for station ids coming from deep links.
///
/// Station ids come from many different APIs — short numeric codes
/// (e-control), UUIDs (Tankerkoenig), slug-like strings (Prix Carburants).
/// We accept anything safe to round-trip through a URL path segment and
/// reject everything else (shell metacharacters, path traversal, HTML,
/// very long strings) so a forged deep link can't crash downstream code.
final _pattern = RegExp(r'^[A-Za-z0-9._-]{1,128}$');

bool isValidStationId(String? id) => id != null && _pattern.hasMatch(id);
