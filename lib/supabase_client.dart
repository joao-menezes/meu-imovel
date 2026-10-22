import 'package:supabase_flutter/supabase_flutter.dart';

/// Atalho para o client do Supabase já inicializado em main().
SupabaseClient get supabase => Supabase.instance.client;
