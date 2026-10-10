import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const url = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://fdvnqqjekkhtxobvcbqx.supabase.co');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'SUPABASE_ANON_KEY_REQUIRED');

  static Future<void> initialize() async {
    if (anonKey == 'SUPABASE_ANON_KEY_REQUIRED' && kDebugMode) debugPrint('Supabase not configured: pass --dart-define=SUPABASE_ANON_KEY=...');
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }
}
