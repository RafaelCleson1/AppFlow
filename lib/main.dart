import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hdwkiaibplmnzxqcodas.supabase.co',
    publishableKey: 'sb_publishable_yMHl-dXPQOEHmOGQiVbAVg_5UGJJLyi',
  );

  runApp(const LivroReceitasApp());
}

class LivroReceitasApp extends StatelessWidget {
  const LivroReceitasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Livro de Receitas',
      home: const HomePage(),
    );
  }
}
