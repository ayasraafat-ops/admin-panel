import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/registration.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  static Future<List<Registration>> fetchRegistrations() async {
    final response = await _client
        .from('registrations')
        .select('*')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Registration.fromJson(json))
        .toList();
  }

  static Future<void> deleteRegistration(int id) async {
    await _client.from('registrations').delete().eq('id', id);
  }

  static Future<void> deleteAllRegistrations() async {
    await _client.from('registrations').delete().gte('id', 0);
  }

  static bool get isConnected {
    try {
      return _client != null;
    } catch (_) {
      return false;
    }
  }
}