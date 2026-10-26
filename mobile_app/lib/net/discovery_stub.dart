/// Web build: derive the API host from the current page URL.
/// Works when the page is opened via localhost OR the PC's LAN IP.
Future<String?> discoverApiBase(
    {required String current, required bool overridden}) async {
  if (overridden || current.isEmpty) return null;
  final host = Uri.base.host;
  if (host.isEmpty) return null;
  if (host == 'localhost' || host == '127.0.0.1') return null;
  return 'http://$host:5000/api';
}
