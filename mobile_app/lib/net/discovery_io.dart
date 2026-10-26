import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const Duration _socketTimeout = Duration(milliseconds: 350);
const Duration _httpTimeout = Duration(seconds: 2);

const List<String> _skipInterfaceHints = [
  'rmnet', 'ccmni', 'dummy', 'loopback', 'p2p', 'tun', 'utun',
  'bluetooth', 'vmware', 'vethernet', 'hyper-v', 'isatap', 'teredo',
];

/// Auto-discover the SmartTrack backend on the LAN (Android/desktop).
/// Order: cached base → localhost/emulator → scan private subnets on :5000.
/// Returns null to keep the current default.
Future<String?> discoverApiBase(
    {required String current, required bool overridden}) async {
  if (overridden) return null;
  try {
    return await _discover(current);
  } catch (_) {
    return null;
  }
}

Future<String?> _discover(String current) async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString('api_base');
  if (cached != null && await _healthy(cached)) return cached;

  final candidates = <String>{
    if (current.isNotEmpty) current,
    'http://localhost:5000/api',
    'http://10.0.2.2:5000/api',
  };

  try {
    final ifaces = await NetworkInterface.list(
      includeLinkLocal: false,
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    final seenBases = <String>{};
    for (final ni in ifaces) {
      final lname = ni.name.toLowerCase();
      if (_skipInterfaceHints.any(lname.contains)) continue;
      for (final a in ni.addresses) {
        final parts = a.address.split('.');
        if (parts.length != 4 || !_isPrivate(parts)) continue;
        final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
        if (!seenBases.add(subnet)) continue;
        for (var i = 1; i <= 254; i++) {
          final ip = '$subnet.$i';
          if (ip == a.address) continue;
          candidates.add('http://$ip:5000/api');
        }
      }
    }
  } catch (_) {}

  final found = await _probe(candidates.toList());
  if (found != null) {
    await prefs.setString('api_base', found);
    return found;
  }
  return null;
}

bool _isPrivate(List<String> p) {
  final o0 = int.tryParse(p[0]) ?? 0;
  final o1 = int.tryParse(p[1]) ?? 0;
  if (o0 == 10) return true;
  if (o0 == 192 && o1 == 168) return true;
  if (o0 == 172 && o1 >= 16 && o1 <= 31) return true;
  return false;
}

Future<bool> _healthy(String base) async {
  try {
    final res =
        await http.get(Uri.parse('$base/health')).timeout(_httpTimeout);
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

Future<String?> _probe(List<String> bases) async {
  const chunk = 40;
  for (var i = 0; i < bases.length; i += chunk) {
    final batch = bases.sublist(
        i, i + chunk > bases.length ? bases.length : i + chunk);
    final results = await Future.wait(batch.map((b) async {
      final uri = Uri.tryParse(b);
      if (uri == null) return null;
      try {
        final sock = await Socket.connect(uri.host, 5000,
            timeout: _socketTimeout);
        sock.destroy();
        if (await _healthy(b)) return b;
      } catch (_) {}
      return null;
    }));
    for (final r in results) {
      if (r != null) return r;
    }
  }
  return null;
}
