import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:zetzy/core/constants/supabase_schema.dart';

/// Reads `supabase.json` from the project root in non-release desktop builds
/// when `--dart-define` flags were not supplied by the IDE/runner.
({String url, String anonKey})? loadDevSupabaseConfig() {
  if (kReleaseMode) return null;
  if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return null;
  if (Platform.environment.containsKey('FLUTTER_TEST')) return null;

  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    final candidate = File(p.join(dir.path, 'supabase.json'));
    if (candidate.existsSync()) {
      try {
        final decoded = jsonDecode(candidate.readAsStringSync());
        if (decoded is Map<String, dynamic>) {
          final url = SupabaseConfig.normalizeUrl(
            (decoded['SUPABASE_URL'] as String?) ?? '',
          );
          final anonKey = ((decoded['SUPABASE_ANON_KEY'] as String?) ?? '')
              .trim();
          if (url.isNotEmpty && anonKey.isNotEmpty) {
            return (url: url, anonKey: anonKey);
          }
        }
      } catch (e) {
        debugPrint('Failed to read supabase.json: $e');
      }
      return null;
    }

    // Stop walking up once we hit or pass pubspec.yaml, or reach filesystem root.
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) break;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}
