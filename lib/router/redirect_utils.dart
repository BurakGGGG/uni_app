String? localRedirectPathFromParam(String? value) {
  final path = value?.trim();
  if (path == null || path.isEmpty) return null;

  final uri = Uri.tryParse(path);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  if (!path.startsWith('/')) return null;

  return path;
}

String routeWithLocalFrom(String route, String? from) {
  final redirectPath = localRedirectPathFromParam(from);
  if (redirectPath == null) return route;

  return Uri(path: route, queryParameters: {'from': redirectPath}).toString();
}
