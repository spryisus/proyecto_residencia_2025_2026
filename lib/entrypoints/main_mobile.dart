import 'package:flutter/material.dart';
import '../app/config/supabase_client.dart';
import '../main.dart' as app;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSupabaseConfig.initialize();
  runApp(const app.MyApp());
}

